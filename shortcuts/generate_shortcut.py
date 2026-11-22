#!/usr/bin/env python3
"""Generate the unsigned CargasCalc.shortcut file.

The shortcut asks for four amounts, splits the pot to the cent, prints each
share and payout, and adds a settle-up section when someone is over their
share. It uses only built-in Shortcuts actions.

Run this script, then sign the output on macOS:

    python3 shortcuts/generate_shortcut.py
    plutil -convert binary1 shortcuts/CargasCalc.shortcut
    shortcuts sign --mode anyone --input shortcuts/CargasCalc.shortcut \
        --output shortcuts/CargasCalc-signed.shortcut
"""

from pathlib import Path
from plistlib import FMT_XML, dump
from uuid import uuid4

PEOPLE = ["Imran", "Bambang", "Danii"]

actions = []


def new_id():
    return str(uuid4()).upper()


def utf16_len(text):
    return len(text.encode("utf-16-le")) // 2


class Out:
    def __init__(self, action_id, name):
        self.action_id = action_id
        self.name = name


class Var:
    def __init__(self, name):
        self.name = name


def output_attachment(out):
    return {
        "Value": {
            "OutputUUID": out.action_id,
            "OutputName": out.name,
            "Type": "ActionOutput",
        },
        "WFSerializationType": "WFTextTokenAttachment",
    }


def variable_attachment(name):
    return {
        "Value": {"Type": "Variable", "VariableName": name},
        "WFSerializationType": "WFTextTokenAttachment",
    }


def attachment(source):
    if isinstance(source, Out):
        return output_attachment(source)
    if isinstance(source, Var):
        return variable_attachment(source.name)
    raise TypeError(source)


def token(parts):
    text = ""
    attachments = {}

    for part in parts:
        if isinstance(part, str):
            text += part
            continue

        offset = utf16_len(text)
        text += "\ufffc"
        attachments[f"{{{offset}, 1}}"] = attachment(part)["Value"]

    if not attachments:
        return text

    return {
        "Value": {"string": text, "attachmentsByRange": attachments},
        "WFSerializationType": "WFTextTokenString",
    }


def add(identifier, params):
    actions.append(
        {
            "WFWorkflowActionIdentifier": identifier,
            "WFWorkflowActionParameters": params,
        }
    )


def ask(prompt, name):
    action_id = new_id()
    add(
        "is.workflow.actions.ask",
        {
            "WFAskActionPrompt": prompt,
            "WFInputType": "Number",
            "UUID": action_id,
            "CustomOutputName": name,
        },
    )
    return Out(action_id, name)


def calculate(name, parts):
    action_id = new_id()
    add(
        "is.workflow.actions.calculateexpression",
        {
            "WFMathExpression": token(parts),
            "Input": token(parts),
            "UUID": action_id,
            "CustomOutputName": name,
        },
    )
    return Out(action_id, name)


def format_number(name, source):
    if not isinstance(source, Out) or actions[-1]["WFWorkflowActionParameters"].get("UUID") != source.action_id:
        raise ValueError("Format Number must directly follow its input: " + name)

    action_id = new_id()
    add(
        "is.workflow.actions.format.number",
        {
            "WFNumberFormatSpecifier": "%.2f",
            "WFNumberFormatDecimalPlaces": 2,
            "UUID": action_id,
            "CustomOutputName": name,
        },
    )
    return Out(action_id, name)


def set_variable(name, parts):
    add(
        "is.workflow.actions.setvariable",
        {
            "WFVariableName": name,
            "WFInput": token(parts),
        },
    )


def text_action(name, parts):
    action_id = new_id()
    add(
        "is.workflow.actions.gettext",
        {
            "WFTextActionText": token(parts),
            "UUID": action_id,
            "CustomOutputName": name,
        },
    )
    return Out(action_id, name)


def conditional_input(source):
    return {
        "Type": "Variable",
        "Variable": attachment(source),
    }


def comment(text):
    add(
        "is.workflow.actions.comment",
        {
            "WFCommentActionText": text,
        },
    )


def replace_text(name, source, find, replacement):
    action_id = new_id()
    add(
        "is.workflow.actions.text.replace",
        {
            "WFInput": token([source]),
            "WFReplaceTextFind": find,
            "WFReplaceTextReplace": replacement,
            "UUID": action_id,
            "CustomOutputName": name,
        },
    )
    return Out(action_id, name)


def if_start(group, source, condition, number=None, text=None, note=None):
    params = {
        "GroupingIdentifier": group,
        "WFControlFlowMode": 0,
        "WFCondition": condition,
        "WFInput": conditional_input(source),
    }
    if number is not None:
        params["WFNumberValue"] = str(number)
    if text is not None:
        params["WFConditionalActionString"] = text
    if note:
        comment(note + "\n- Wiring: uses the condition input above; sets the branch text below.")
    add("is.workflow.actions.conditional", params)


def otherwise(group):
    add(
        "is.workflow.actions.conditional",
        {
            "GroupingIdentifier": group,
            "WFControlFlowMode": 1,
        },
    )


def if_end(group):
    add(
        "is.workflow.actions.conditional",
        {
            "GroupingIdentifier": group,
            "WFControlFlowMode": 2,
        },
    )


def show_result(parts):
    add(
        "is.workflow.actions.showresult",
        {
            "Text": token(parts),
        },
    )


def build():
    comment("CargasCalc — split a shared cash pot three ways, with settle-up.")
    comment(
        "Shortcuts generated by Shortcuts Playground.\n\n"
        "Prompts:\n"
        "- Cash in hand (RM)\n"
        "- Imran took (RM)\n"
        "- Bambang took (RM)\n"
        "- Danii took (RM)"
    )

    cash = ask("Cash in hand (RM)", "Cash")
    imran = ask("Imran took (RM)", "Imran")
    bambang = ask("Bambang took (RM)", "Bambang")
    danii = ask("Danii took (RM)", "Danii")
    advances = [imran, bambang, danii]

    cash_value = calculate("Cash Value", [cash])
    cash_text = format_number("Cash Text", cash_value)

    total = calculate(
        "Total Cents",
        ["rint((", cash, " + ", imran, " + ", bambang, " + ", danii, ") * 100)"],
    )

    pot = calculate("Pot", ["(", total, ") / 100"])
    pot_text = format_number("Pot Text", pot)

    taken = calculate(
        "Taken",
        ["rint((", imran, " + ", bambang, " + ", danii, ") * 100) / 100"],
    )
    taken_text = format_number("Taken Text", taken)

    people = []

    for index, advance in enumerate(advances):
        share = calculate(
            f"Share {index + 1}",
            ["floor((", total, f" + {2 - index}) / 3)"],
        )
        share_value = calculate(f"Share {index + 1} Ringgit", ["(", share, ") / 100"])
        share_text = format_number(f"Share {index + 1} Text", share_value)

        payout = calculate(
            f"Payout {index + 1}",
            ["(", share, " - rint(", advance, " * 100))"],
        )
        payout_value = calculate(f"Payout {index + 1} Ringgit", ["(", payout, ") / 100"])
        payout_text = format_number(f"Payout {index + 1} Text", payout_value)

        owed_value = calculate(f"Owed {index + 1} Ringgit", ["fabs(", payout, ") / 100"])
        owed_text = format_number(f"Owed {index + 1} Text", owed_value)

        people.append(
            {
                "share": share,
                "share_text": share_text,
                "payout": payout,
                "payout_text": payout_text,
                "owed_text": owed_text,
            }
        )

    for index, person in enumerate(PEOPLE):
        group = new_id()
        if_start(
            group,
            people[index]["payout"],
            0,
            0,
            note=f"Payout line for {PEOPLE[index]}.",
        )
        set_variable(
            f"Line {index + 1}",
            [
                person,
                ": owes RM ",
                people[index]["owed_text"],
                " (share RM ",
                people[index]["share_text"],
                ")",
            ],
        )
        otherwise(group)
        set_variable(
            f"Line {index + 1}",
            [
                person,
                ": gets RM ",
                people[index]["payout_text"],
                " (share RM ",
                people[index]["share_text"],
                ")",
            ],
        )
        if_end(group)

    settle_start = text_action("Settle Start", ["\u200b"])
    set_variable("Settle", [settle_start])

    for index in range(3):
        first = (index + 1) % 3
        second = (index + 2) % 3
        group = new_id()
        if_start(
            group,
            people[index]["payout"],
            0,
            0,
            note=f"Settle up when {PEOPLE[index]} is over their share.",
        )

        debt = calculate(f"Debt {index + 1}", ["0 - ", people[index]["payout"]])
        first_positive = calculate(
            f"First Positive {index + 1}",
            [
                "((",
                people[first]["payout"],
                ") + fabs(",
                people[first]["payout"],
                ")) / 2",
            ],
        )
        second_positive = calculate(
            f"Second Positive {index + 1}",
            [
                "((",
                people[second]["payout"],
                ") + fabs(",
                people[second]["payout"],
                ")) / 2",
            ],
        )

        first_amount = calculate(
            f"First Amount {index + 1}",
            [
                "floor((",
                debt,
                ") * (",
                first_positive,
                ") / ((",
                first_positive,
                ") + (",
                second_positive,
                "))) + ceil((fmod((",
                debt,
                ") * (",
                first_positive,
                "), (",
                first_positive,
                ") + (",
                second_positive,
                ")) - fmod((",
                debt,
                ") * (",
                second_positive,
                "), (",
                first_positive,
                ") + (",
                second_positive,
                "))) / ((",
                first_positive,
                ") + (",
                second_positive,
                ")))",
            ],
        )
        second_amount = calculate(
            f"Second Amount {index + 1}",
            ["(", debt, ") - (", first_amount, ")"],
        )

        first_value = calculate(
            f"First Value {index + 1}", ["(", first_amount, ") / 100"]
        )
        first_text = format_number(f"First Text {index + 1}", first_value)

        second_value = calculate(
            f"Second Value {index + 1}", ["(", second_amount, ") / 100"]
        )
        second_text = format_number(f"Second Text {index + 1}", second_value)

        first_group = new_id()
        if_start(
            first_group,
            first_positive,
            2,
            0,
            note=f"Include {PEOPLE[index]}'s payment to {PEOPLE[first]}.",
        )
        set_variable(
            "Settle",
            [
                Var("Settle"),
                "\n",
                PEOPLE[index],
                " pays ",
                PEOPLE[first],
                ": RM ",
                first_text,
            ],
        )
        if_end(first_group)

        second_group = new_id()
        if_start(
            second_group,
            second_positive,
            2,
            0,
            note=f"Include {PEOPLE[index]}'s payment to {PEOPLE[second]}.",
        )
        set_variable(
            "Settle",
            [
                Var("Settle"),
                "\n",
                PEOPLE[index],
                " pays ",
                PEOPLE[second],
                ": RM ",
                second_text,
            ],
        )
        if_end(second_group)

        if_end(group)

    def body():
        return [
            "Total pot: RM ",
            pot_text,
            "\nCash in hand: RM ",
            cash_text,
            "\nTaken early: RM ",
            taken_text,
            "\n\n",
            Var("Line 1"),
            "\n",
            Var("Line 2"),
            "\n",
            Var("Line 3"),
        ]

    settle_group = new_id()
    if_start(
        settle_group,
        Var("Settle"),
        99,
        text="pays",
        note="Show the settle-up block only when a transfer exists.",
    )
    clean_settle = replace_text("Clean Settle", Var("Settle"), "\u200b", "")
    show_result(body() + ["\n\nSettle up:", clean_settle])
    otherwise(settle_group)
    show_result(body())
    if_end(settle_group)


def main():
    build()

    workflow = {
        "WFWorkflowActions": actions,
        "WFWorkflowClientVersion": "2700.0.4",
        "WFWorkflowHasOutputFallback": False,
        "WFWorkflowHasShortcutInputVariables": False,
        "WFWorkflowIcon": {
            "WFWorkflowIconGlyphNumber": 59511,
            "WFWorkflowIconStartColor": 4282601983,
        },
        "WFWorkflowImportQuestions": [],
        "WFWorkflowInputContentItemClasses": [],
        "WFWorkflowMinimumClientVersion": 900,
        "WFWorkflowMinimumClientVersionString": "900",
        "WFWorkflowName": "CargasCalc",
        "WFWorkflowOutputContentItemClasses": [],
        "WFWorkflowTypes": [],
    }

    target = Path(__file__).with_name("CargasCalc.shortcut")
    with target.open("wb") as handle:
        dump(workflow, handle, fmt=FMT_XML)

    print(f"Wrote {target} with {len(actions)} actions")


if __name__ == "__main__":
    main()
