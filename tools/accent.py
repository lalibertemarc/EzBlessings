"""Translates every EzBlessings line (Lines.lua) into a dwarf accent (or orc/troll) with the local LLM
(Ollama), and writes Lines<Accent>.lua: the same tables, under ns.ACCENT_LINES[accent].

Borrows RpBuffBeg's tools (../RpBuffBeg/tools/generate.py): its Ollama call, accent descriptions and
plain -> accent example pairs (matching lines in RpBuffBeg's Voices.lua / Voices<Accent>.lua).

Needs Ollama running (https://ollama.com) with the model pulled:  ollama pull llama3.1:8b

    python tools/accent.py                                  # every table, dwarf
    python tools/accent.py --only REFRESH_LINES,LINES       # retranslate just those, keep the rest
    python tools/accent.py --verbose                        # each translation next to its original

%t, %b and %p come through untouched; lad/lass becomes %l (the target's "lad" or "lass"). Expressions
in a line, like (ns.ERA and "round" or "hour"), are kept as they are. Lines whose translation breaks a
rule are tried once more and then left out.
"""
import argparse
import random
import re
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "Lines.lua"
RPBUFFBEG_TOOLS = ROOT.parent / "RpBuffBeg" / "tools"
sys.path.insert(0, str(RPBUFFBEG_TOOLS))
try:
    import generate as g
except ImportError:
    sys.exit(f"Needs RpBuffBeg's tools next to this addon: {RPBUFFBEG_TOOLS / 'generate.py'} not found.")

ACCENTS = [a for a in g.SOURCES if a != "plain"]
BATCH = 10
PAIRS = 16
TEMPERATURE = 0.6
# Longest line before %t/%b/%p are filled in: a full name and "Greater Blessing of Wisdom" add about
# 40 more, and /say cuts off at 255.
MAX_LEN = 180

# Lines.lua placeholder <-> what the model sees.
TO_MODEL = {"%t": "{name}", "%b": "{blessing}", "%p": "{paladin}"}
FROM_MODEL = {v: k for k, v in TO_MODEL.items()} | {"{lad}": "%l"}

# What each table is for, so the model knows the situation.
SITUATION = {
    "LINES": "casting a blessing on another player",
    "BLESSING_LINES": "casting a blessing on another player",
    "CLASS_LINES": "casting a blessing on another player, with a nod to their class",
    "UNWORTHY_LINES": "refusing to bless someone whose guild follows false gods (Olympus): firm and kind, never "
                      "cruel, always leaving the way back through repentance open",
    "MIGHT_ON_CASTER_LINES": "giving Blessing of Might to a spellcaster, which does nothing for them: dry humor",
    "RENEW_OTHER_LINES": "renewing a blessing another paladin, {paladin}, already gave the target",
    "REFRESH_LINES": "renewing your own blessing on the target before it fades",
}


class Line:
    """One line: text with {placeholders} for the model, and the Lua expressions some of them stand for."""

    def __init__(self, text, exprs):
        self.text, self.exprs = text, exprs

    def lua(self):
        parts = []
        keys = "|".join(re.escape(k) for k in self.exprs) or r"(?!)"
        for piece in re.split(f"({keys})", self.text):
            if piece in self.exprs:
                parts.append(self.exprs[piece])
            elif piece:
                for a, b in FROM_MODEL.items():
                    piece = piece.replace(a, b)
                parts.append(g.lua_string(piece))
        return " .. ".join(parts)


def parse_expr(src):
    """A Lua line expression ("..." .. (expr) .. "...") -> Line, or None if it's not one."""
    text, exprs, i = "", {}, 0
    while i < len(src):
        c = src[i]
        if c.isspace() or src.startswith("..", i):
            i += 2 if c == "." else 1
        elif c == '"':
            m = re.match(r'"((?:[^"\\]|\\.)*)"', src[i:])
            text += m.group(1).replace('\\"', '"').replace("\\\\", "\\")
            i += m.end()
        elif c == "(":
            depth, j = 0, i
            while j < len(src):
                if src[j] == '"':
                    j += re.match(r'"(?:[^"\\]|\\.)*"', src[j:]).end()
                    continue
                depth += {"(": 1, ")": -1}.get(src[j], 0)
                j += 1
                if depth == 0:
                    break
            expr = src[i:j]
            # Named after its last string, (ns.ERA and "round" or "hour") -> {hour}.
            words = re.findall(r'"(\w+)"', expr)
            key = "{%s}" % (words[-1] if words else f"x{len(exprs) + 1}")
            exprs[key] = expr
            text += key
            i = j
        else:
            break  # trailing comma or comment
    if not text:
        return None
    for a, b in TO_MODEL.items():
        text = text.replace(a, b)
    return Line(text.replace("%l", "{lad}"), exprs)


def parse_lines(path):
    """Lines.lua (or a Lines<Accent>.lua) -> {table: [Line] or {key: [Line]}}, in file order."""
    out, top, sub = {}, None, None
    for raw in path.read_text(encoding="utf-8").splitlines():
        m = re.match(r"^(?:ns\.)?(\w+) = \{\s*(--.*)?$", raw)
        if m:
            top, sub = m.group(1), None
            continue
        m = re.match(r"^    (\w+) = \{\s*(--.*)?$", raw)
        if m and top:
            if not isinstance(out.get(top), dict):
                out[top] = {}
            sub = out[top].setdefault(m.group(1), [])
            continue
        if re.match(r"^    \},?\s*$", raw):
            sub = None
            continue
        if re.match(r"^\},?\s*$", raw):
            top = sub = None
            continue
        m = re.match(r'^\s+(".*?),?\s*(?:--[^"]*)?$', raw)
        if m and top:
            line = parse_expr(m.group(1))
            if line:
                (sub if sub is not None else out.setdefault(top, [])).append(line)
    return out


def examples(pairs):
    """RpBuffBeg's plain -> accent pairs, with its placeholders swapped for ours."""
    def fix(s):
        return s.replace("{buff}", "{blessing}").replace("{me}", "me").replace("{my}", "my")
    shown = random.sample(pairs, min(PAIRS, len(pairs)))
    return [(fix(a), fix(b)) for a, b in shown]


def prompt(accent, table, pairs, lines):
    holders = sorted({h for line in lines for h in re.findall(r"\{\w+\}", line.text)} - {"{lad}"})
    system = (
        "You rewrite short /say chat lines from a classic World of Warcraft roleplayer, a paladin of the Silver "
        "Hand, into an accent. Keep each line's meaning, joke and attitude; change only how it's said, like the "
        "examples. Keep names of people and places (Uther, Lordaeron, Olympus...) as they are.\n"
        f"Accent: {g.ACCENT_STYLE[accent]}"
        + (" You may use {lad}, which becomes 'lad' or 'lass' for the target." if accent == "dwarf" else "") + "\n"
        f"The paladin is {SITUATION.get(table, 'speaking to another player')}.\n"
        f"Keep {', '.join(holders)} exactly as written, with curly braces, as often as in the original. "
        "Don't start a line with {paladin}. Don't add phrases or tags at the end: about as long as the original. "
        "No *actions*, no emojis, no quotation marks around the line."
    )
    user = (
        "Examples, plain => accent:\n"
        + "\n".join(f"{a}\n=> {b}" for a, b in examples(pairs))
        + f"\n\nRewrite these {len(lines)} lines the same way, one per line, in the same order:\n"
        + "\n".join(f"{i}. {line.text}" for i, line in enumerate(lines, 1))
        + '\n\nReply as JSON: {"lines": ["...", "..."]}'
    )
    return system, user


def check(reply, source, accent):
    """(translated text, None) or (None, why it was rejected)."""
    for a, b in g.TYPOGRAPHY.items():
        reply = reply.replace(a, b)
    reply = re.sub(r"^\s*(?:[-*\d.)]+\s+)?", "", reply).strip().strip('"').strip()
    if accent == "dwarf":
        reply = re.sub(r"(?<!\{)\b(lad|lass|laddie|lassie)\b(?!\})", "{lad}", reply, flags=re.I)
    if not reply.isascii():
        return None, "non-ascii"
    if any(c in reply for c in "|*#%\n"):
        return None, "bad char"
    if len(reply) > MAX_LEN:
        return None, "too long"
    wanted = sorted(h for h in re.findall(r"\{\w+\}", source.text) if h != "{lad}")
    got = sorted(h for h in re.findall(r"\{\w+\}", reply) if h != "{lad}")
    if got != wanted or re.search(r"[{}]", re.sub(r"\{\w+\}", "", reply)):
        return None, "placeholders changed"
    if reply.startswith("{paladin}"):
        return None, "starts with {paladin}"
    if len(reply) > len(source.text) * 1.4 + 10:
        return None, "padded"
    if g.norm(reply) == g.norm(source.text):
        return None, "unchanged"
    return reply, None


def translate(args, accent, table, pairs, source):
    """source Lines in the accent, in order; lines that fail twice are left out."""
    done, rejected = {}, {}
    todo = list(range(len(source)))
    for _ in range(2):
        failed = []
        for start in range(0, len(todo), BATCH):
            batch = todo[start:start + BATCH]
            system, user = prompt(accent, table, pairs, [source[i] for i in batch])
            try:
                raw = g.ollama(args.host, args.model, system, user, TEMPERATURE)
            except (ValueError, KeyError):
                raw = []
            if len(raw) != len(batch):
                rejected["wrong count"] = rejected.get("wrong count", 0) + 1
                failed += batch
                continue
            for i, reply in zip(batch, raw):
                text, why = check(reply, source[i], accent)
                if why:
                    rejected[why] = rejected.get(why, 0) + 1
                    failed.append(i)
                    if args.verbose:
                        print(f"      x {why}: {reply}")
                    continue
                done[i] = Line(text, source[i].exprs)
                if args.verbose:
                    print(f"      {source[i].text}\n      => {text}")
        todo = failed
        if not todo:
            break
    for i in todo:
        print(f"      left out: {source[i].text}")
    return [done[i] for i in sorted(done)], rejected


def write_lua(path, accent, tables):
    out = [
        f"-- EzBlessings lines with a {accent} accent, translated from Lines.lua by a local LLM (tools/accent.py):",
        "-- same tables and placeholders, plus %l = \"lad\" or \"lass\" for the target. Rebuilt by the tool:",
        "-- rerun it (--only TABLE) rather than editing by hand, or hand edits are lost.",
        "local _, ns = ...",
        "",
        "ns.ACCENT_LINES = ns.ACCENT_LINES or {}",
        f"ns.ACCENT_LINES.{accent} = {{",
    ]
    for table, lines in tables.items():
        out.append(f"{table} = {{")
        if isinstance(lines, dict):
            for key, sub in lines.items():
                out.append(f"    {key} = {{")
                out.extend(f"        {line.lua()}," for line in sub)
                out.append("    },")
        else:
            out.extend(f"    {line.lua()}," for line in lines)
        out.append("},")
    out.append("}")
    path.write_text("\n".join(out) + "\n", encoding="utf-8", newline="\n")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("accent", nargs="?", default="dwarf", choices=ACCENTS)
    ap.add_argument("--only", help="tables to retranslate, comma-separated (e.g. LINES,REFRESH_LINES); "
                                   "the others are kept from the existing file")
    ap.add_argument("--model", default="llama3.1:8b")
    ap.add_argument("--host", default="http://localhost:11434")
    ap.add_argument("--verbose", action="store_true", help="print every translation and every rejected line")
    args = ap.parse_args()

    source = parse_lines(SOURCE)
    output = ROOT / f"Lines{args.accent.capitalize()}.lua"
    wanted = list(source)
    kept = {}
    if args.only:
        wanted = args.only.split(",")
        bad = [t for t in wanted if t not in source]
        if bad:
            sys.exit(f"Unknown table: {', '.join(bad)}. Choose from: {', '.join(source)}")
        kept = parse_lines(output) if output.exists() else {}

    try:
        urllib.request.urlopen(f"{args.host}/api/tags", timeout=5)
    except (urllib.error.URLError, OSError):
        sys.exit(f"Can't reach Ollama at {args.host}. Start it (Ollama app, or `ollama serve`) and try again.")

    pairs = [(a, b) for kind in g.KINDS for _, a, b in g.accent_pairs(args.accent)[kind]]
    started = time.time()
    result = {}
    for table, lines in source.items():
        if table not in wanted:
            if table in kept:
                result[table] = kept[table]
            continue
        groups = lines.items() if isinstance(lines, dict) else [(None, lines)]
        for key, sub in groups:
            t = time.time()
            new, rejected = translate(args, args.accent, table, pairs, sub)
            if key:
                result.setdefault(table, {})[key] = new
            else:
                result[table] = new
            skipped = ", ".join(f"{k} {v}" for k, v in sorted(rejected.items())) or "none"
            name = f"{table}.{key}" if key else table
            print(f"{name}: {len(new)}/{len(sub)} ({time.time() - t:.0f}s, rejected: {skipped})")
    write_lua(output, args.accent, result)
    print(f"Done in {(time.time() - started) / 60:.1f} min. Wrote {output.name}.")


if __name__ == "__main__":
    main()
