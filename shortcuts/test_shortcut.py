#!/usr/bin/env python3
"""Run the generated CargasCalc.shortcut action graph with sample inputs.

This is a local interpreter for the small action set the shortcut uses. It
checks the wiring, variables, conditionals and settle-up branches end to end,
but it cannot replace importing the signed shortcut on an iPhone.
"""

import math
import plistlib
import sys
from pathlib import Path

SHORTCUT = Path(__file__).with_name("CargasCalc.shortcut")
FUNCTIONS = {
    "rint": lambda value: math.floor(value + 0.5),
    "floor": math.floor,
    "ceil": math.ceil,
    "fmod": math.fmod,
    "fabs": math.fabs,
}


class Runner:
    def __init__(self, actions, inputs):
        self.actions = actions
        self.inputs = list(inputs)
        self.outputs = {}
        self.variables = {}
        self.results = []
        self.last = None

    def run(self):
        self.run_range(0, len(self.actions))
        return self.results

    def run_range(self, start, end):
        index = start
        while index < end:
            action = self.actions[index]
            ident = action["WFWorkflowActionIdentifier"]
            params = action.get("WFWorkflowActionParameters", {})

            if ident == "is.workflow.actions.comment":
                index += 1
                continue

            if ident == "is.workflow.actions.conditional":
                mode = params.get("WFControlFlowMode")
                if mode != 0:
                    index += 1
                    continue

                group = params.get("GroupingIdentifier")
                otherwise_at, end_at = self.find_block(index, end, group)
                if self.condition(params):
                    self.run_range(index + 1, otherwise_at if otherwise_at is not None else end_at)
                elif otherwise_at is not None:
                    self.run_range(otherwise_at + 1, end_at)
                index = end_at + 1
                continue

            if ident == "is.workflow.actions.ask":
                value = self.inputs.pop(0)
                self.emit(params, value)
            elif ident == "is.workflow.actions.calculateexpression":
                expression = self.resolve(params["WFMathExpression"])
                value = self.evaluate(expression)
                self.emit(params, value)
            elif ident == "is.workflow.actions.format.number":
                if self.last is None:
                    raise RuntimeError("Format Number with no input")
                value = "%.2f" % float(self.last)
                self.emit(params, value)
            elif ident == "is.workflow.actions.text.replace":
                value = str(self.resolve(params["WFInput"]))
                value = value.replace(
                    params["WFReplaceTextFind"],
                    params.get("WFReplaceTextReplace", ""),
                )
                self.emit(params, value)
            elif ident == "is.workflow.actions.gettext":
                value = self.resolve(params["WFTextActionText"])
                self.emit(params, value)
            elif ident == "is.workflow.actions.setvariable":
                self.variables[params["WFVariableName"]] = self.resolve(params["WFInput"])
            elif ident == "is.workflow.actions.showresult":
                self.results.append(self.resolve(params["Text"]))
            else:
                raise RuntimeError("Unsupported action: " + ident)

            index += 1

    def find_block(self, start, end, group):
        depth = 0
        otherwise_at = None
        for index in range(start + 1, end):
            action = self.actions[index]
            if action["WFWorkflowActionIdentifier"] != "is.workflow.actions.conditional":
                continue
            params = action.get("WFWorkflowActionParameters", {})
            if params.get("GroupingIdentifier") != group:
                continue
            mode = params.get("WFControlFlowMode")
            if mode == 0:
                depth += 1
            elif mode == 2:
                if depth == 0:
                    return otherwise_at, index
                depth -= 1
            elif mode == 1 and depth == 0:
                otherwise_at = index
        raise RuntimeError("Unclosed conditional")

    def condition(self, params):
        value = self.resolve(params["WFInput"]["Variable"])
        code = params.get("WFCondition")
        if code == 0:
            return float(value) < float(params["WFNumberValue"])
        if code == 1:
            return float(value) <= float(params["WFNumberValue"])
        if code == 2:
            return float(value) > float(params["WFNumberValue"])
        if code == 3:
            return float(value) >= float(params["WFNumberValue"])
        if code == 4:
            return str(value) == str(params["WFConditionalActionString"])
        if code == 5:
            return str(value) != str(params["WFConditionalActionString"])
        if code == 99:
            return str(params["WFConditionalActionString"]) in str(value)
        if code == 100:
            return value is not None and str(value) != ""
        raise RuntimeError("Unsupported condition " + str(code))

    def emit(self, params, value):
        self.last = value
        if "UUID" in params:
            self.outputs[params["UUID"]] = value

    def resolve(self, value):
        if isinstance(value, str):
            return value
        if not isinstance(value, dict):
            return value

        if value.get("WFSerializationType") == "WFTextTokenAttachment":
            return self.resolve_attachment(value["Value"])

        if value.get("WFSerializationType") == "WFTextTokenString":
            inner = value["Value"]
            text = inner["string"]
            attachments = inner.get("attachmentsByRange", {})
            # Our generated strings use only BMP characters plus U+FFFC.
            chars = list(text)
            for key, attachment in attachments.items():
                offset = int(key.split(",")[0].lstrip("{"))
                chars[offset] = str(self.resolve_attachment(attachment))
            return "".join(chars)

        raise RuntimeError("Unsupported value: " + repr(value))

    def resolve_attachment(self, attachment):
        if attachment.get("Type") == "ActionOutput":
            return self.outputs[attachment["OutputUUID"]]
        if attachment.get("Type") == "Variable":
            return self.variables[attachment["VariableName"]]
        raise RuntimeError("Unsupported attachment: " + repr(attachment))

    def evaluate(self, expression):
        return eval(expression, {"__builtins__": {}}, FUNCTIONS)


def expected(cash, advances):
    total = round((cash + sum(advances)) * 100)
    shares = [math.floor((total + (2 - index)) / 3) for index in range(3)]
    payouts = [shares[index] - round(advances[index] * 100) for index in range(3)]

    def fmt(cents):
        return "%.2f" % (cents / 100)

    lines = []
    for index, name in enumerate(["Imran", "Bambang", "Danii"]):
        if payouts[index] < 0:
            lines.append(
                f"{name}: owes RM {fmt(-payouts[index])} "
                f"(share RM {fmt(shares[index])})"
            )
        else:
            lines.append(
                f"{name}: gets RM {fmt(payouts[index])} "
                f"(share RM {fmt(shares[index])})"
            )

    settle = []
    for index in range(3):
        if payouts[index] >= 0:
            continue
        first = (index + 1) % 3
        second = (index + 2) % 3
        debt = -payouts[index]
        first_positive = (payouts[first] + abs(payouts[first])) / 2
        second_positive = (payouts[second] + abs(payouts[second])) / 2
        total_positive = first_positive + second_positive
        first_amount = math.floor(debt * first_positive / total_positive) + math.ceil(
            (
                math.fmod(debt * first_positive, total_positive)
                - math.fmod(debt * second_positive, total_positive)
            )
            / total_positive
        )
        second_amount = debt - first_amount
        debtor = ["Imran", "Bambang", "Danii"][index]
        if first_positive > 0:
            settle.append(
                f"{debtor} pays {['Imran', 'Bambang', 'Danii'][first]}: "
                f"RM {fmt(first_amount)}"
            )
        if second_positive > 0:
            settle.append(
                f"{debtor} pays {['Imran', 'Bambang', 'Danii'][second]}: "
                f"RM {fmt(second_amount)}"
            )

    body = [
        f"Total pot: RM {fmt(total)}",
        f"Cash in hand: RM {fmt(round(cash * 100))}",
        f"Taken early: RM {fmt(round(sum(advances) * 100))}",
        "",
        *lines,
    ]
    if settle:
        body.extend(["", "Settle up:", *settle])
    return "\n".join(body)


def main():
    actions = plistlib.load(SHORTCUT.open("rb"))["WFWorkflowActions"]
    cases = [
        (240, [50, 0, 30]),
        (10, [20, 0, 0]),
        (0, [20, 20, 0]),
        (10, [30, 5, 0]),
        (1, [10, 0, 0]),
        (2000, [500, 250, 0]),
        (0, [10, 10, 0]),
        (0, [0, 0, 0]),
    ]

    failed = False
    for cash, advances in cases:
        runner = Runner(actions, [cash, *advances])
        results = runner.run()
        actual = results[0] if results else ""
        wanted = expected(cash, advances)
        if actual != wanted:
            failed = True
            print("FAIL", cash, advances)
            print("--- wanted ---")
            print(wanted)
            print("--- actual ---")
            print(actual)
        else:
            print("PASS", cash, advances)

    if failed:
        sys.exit(1)


if __name__ == "__main__":
    main()
