#!/usr/bin/env python3
"""
Automated Test Suite for Don't Starve Mod: Elaina_Fix
Runs locally and on GitHub Actions CI.
Covers:
- Lua syntax balance and block nesting
- Mod metadata (modinfo.lua) and configuration options
- Asset registration vs disk files (textures, sounds, anims, atlases)
- Prefab registration vs scripts/prefabs/ implementation
- XML Atlas formats and UV coordinate bounds
- KTEX binary headers and power-of-two dimensions
- Animation archive (.zip) integrity and bin contents
- Sound bank (.fsb/.fev) magic headers and sizes
- Prefabs, Brains, StateGraphs, Components and Widgets returns
- Cleanliness (no merge conflict markers)
"""

import os
import sys
import re
import glob
import struct
import zipfile
import unittest
import xml.etree.ElementTree as ET

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


class TestLuaSyntaxAndStructure(unittest.TestCase):
    """Validates Lua syntax, bracket balance, and block structure across all mod scripts."""

    def get_all_lua_files(self):
        lua_files = []
        for root, _, files in os.walk(REPO_ROOT):
            if '.git' in root or 'scratch' in root or '.system_generated' in root:
                continue
            for f in files:
                if f.endswith('.lua'):
                    lua_files.append(os.path.join(root, f))
        return lua_files

    def test_lua_brackets_balanced(self):
        """Verify that all parentheses, braces, and brackets are perfectly balanced."""
        brackets = {'(': ')', '{': '}', '[': ']'}
        for fpath in self.get_all_lua_files():
            with open(fpath, 'r', encoding='utf-8', errors='ignore') as f:
                code = f.read()

            clean = re.sub(r'--\[\[.*?\]\]', '', code, flags=re.DOTALL)
            clean = re.sub(r'--[^\n]*', '', clean)
            clean = re.sub(r'"(\\.|[^"\\])*"', '""', clean)
            clean = re.sub(r"'(\\.|[^'\\])*'", "''", clean)
            clean = re.sub(r'\[\[.*?\]\]', '""', clean, flags=re.DOTALL)

            stack = []
            rel_path = os.path.relpath(fpath, REPO_ROOT)
            for lno, line in enumerate(clean.split('\n'), 1):
                for ch in line:
                    if ch in '({[':
                        stack.append((ch, lno))
                    elif ch in ')}]':
                        self.assertTrue(len(stack) > 0, f"Unmatched closing '{ch}' at {rel_path}:{lno}")
                        top, top_lno = stack.pop()
                        self.assertEqual(brackets[top], ch, f"Mismatched bracket '{top}' at {rel_path}:{top_lno} with '{ch}' at line {lno}")
            self.assertEqual(len(stack), 0, f"Unclosed brackets in {rel_path}: {stack}")

    def test_lua_block_nesting(self):
        """Verify that Lua control blocks (if/do/function/repeat vs end/until) are balanced."""
        for fpath in self.get_all_lua_files():
            with open(fpath, 'r', encoding='utf-8', errors='ignore') as f:
                code = f.read()

            clean = re.sub(r'--\[\[.*?\]\]', '', code, flags=re.DOTALL)
            clean = re.sub(r'--[^\n]*', '', clean)
            clean = re.sub(r'"(\\.|[^"\\])*"', '""', clean)
            clean = re.sub(r"'(\\.|[^'\\])*'", "''", clean)
            clean = re.sub(r'\[\[.*?\]\]', '""', clean, flags=re.DOTALL)

            token_re = re.compile(r'\b(if|do|function|repeat|end|until)\b')
            stack = []
            rel_path = os.path.relpath(fpath, REPO_ROOT)

            for m in token_re.finditer(clean):
                t = m.group(1)
                pos = m.start()
                line = code.count('\n', 0, pos) + 1

                if t in ('if', 'do', 'function', 'repeat'):
                    stack.append((t, line))
                elif t == 'end':
                    self.assertTrue(len(stack) > 0, f"Unexpected 'end' with no open block at {rel_path}:{line}")
                    top, top_line = stack.pop()
                    self.assertIn(top, ('if', 'do', 'function'), f"Mismatched 'end' for '{top}' (from line {top_line}) at {rel_path}:{line}")
                elif t == 'until':
                    self.assertTrue(len(stack) > 0, f"Unexpected 'until' with no open block at {rel_path}:{line}")
                    top, top_line = stack.pop()
                    self.assertEqual(top, 'repeat', f"Mismatched 'until' for '{top}' (from line {top_line}) at {rel_path}:{line}")

            self.assertEqual(len(stack), 0, f"Unclosed blocks at EOF in {rel_path}: {stack}")


class TestModInfoAndConfiguration(unittest.TestCase):
    """Validates modinfo.lua format, required metadata, and configuration options."""

    def setUp(self):
        self.modinfo_path = os.path.join(REPO_ROOT, "modinfo.lua")
        self.assertTrue(os.path.isfile(self.modinfo_path), "modinfo.lua must exist in root")
        with open(self.modinfo_path, 'r', encoding='utf-8') as f:
            self.content = f.read()

    def test_required_metadata_fields(self):
        required_fields = ["name", "description", "author", "version", "api_version"]
        for field in required_fields:
            pattern = rf'^{field}\s*='
            self.assertTrue(re.search(pattern, self.content, re.MULTILINE), f"modinfo.lua missing required field: {field}")

    def test_compatibility_flags(self):
        flags = [
            "dont_starve_compatible",
            "reign_of_giants_compatible",
            "shipwrecked_compatible",
            "hamlet_compatible"
        ]
        for flag in flags:
            pattern = rf'^{flag}\s*=\s*true'
            self.assertTrue(re.search(pattern, self.content, re.MULTILINE), f"modinfo.lua should declare: {flag} = true")

    def test_configuration_options_syntax(self):
        self.assertIn("configuration_options", self.content, "modinfo.lua must define configuration_options")
        self.assertIn("wand_sanity_cost", self.content, "modinfo.lua must have wand_sanity_cost setting")
        self.assertIn("stats_per_level", self.content, "modinfo.lua must have stats_per_level setting")

    def test_removed_features_have_no_options(self):
        """Hoki and the Traveler's Pack are disabled until they have their own models."""
        for name in ("hoki_", "pack_size", "broom_companion_cost"):
            self.assertNotIn(name, self.content, f"modinfo.lua still has a '{name}' option for a removed feature")

    def test_every_default_is_an_option(self):
        """A default that isn't one of the options shows a blank entry in the mods menu."""
        blocks = re.findall(r'options\s*=\s*\{(.*?)\n\s*\},\s*default\s*=\s*([^,\n]+)', self.content, re.S)
        self.assertTrue(blocks, "could not parse configuration options")
        for body, default in blocks:
            values = [v.strip() for v in re.findall(r'data\s*=\s*([^}]+)\}', body)]
            self.assertIn(default.strip(), values, f"default {default.strip()} is not one of {values}")


class TestPrefabAndAssetIntegrity(unittest.TestCase):
    """Ensures all prefabs and assets registered in modmain.lua actually exist on disk."""

    def setUp(self):
        self.modmain_path = os.path.join(REPO_ROOT, "modmain.lua")
        self.assertTrue(os.path.isfile(self.modmain_path), "modmain.lua must exist in root")
        with open(self.modmain_path, 'r', encoding='utf-8') as f:
            self.content = f.read()

    def test_all_prefabs_exist(self):
        match = re.search(r'PrefabFiles\s*=\s*\{([^}]+)\}', self.content)
        self.assertIsNotNone(match, "PrefabFiles table must be defined in modmain.lua")
        prefabs = re.findall(r'"([^"]+)"', match.group(1))

        for prefab in prefabs:
            expected_file = os.path.join(REPO_ROOT, "scripts", "prefabs", f"{prefab}.lua")
            self.assertTrue(
                os.path.isfile(expected_file),
                f"Prefab '{prefab}' listed in PrefabFiles but {os.path.relpath(expected_file, REPO_ROOT)} does not exist!"
            )

    def test_all_declared_assets_exist(self):
        asset_matches = re.findall(r'Asset\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\)', self.content)
        self.assertTrue(len(asset_matches) > 0, "Assets must be declared in modmain.lua")

        for asset_type, asset_rel in asset_matches:
            expected_path = os.path.join(REPO_ROOT, asset_rel.replace('/', os.sep))
            self.assertTrue(
                os.path.isfile(expected_path),
                f"Asset '{asset_rel}' ({asset_type}) declared in modmain.lua but file not found on disk!"
            )


class TestXmlAtlases(unittest.TestCase):
    """Validates XML atlas files, texture coordinates, and referenced tex files."""

    def test_all_xml_atlases(self):
        xml_files = []
        for root, _, files in os.walk(REPO_ROOT):
            if '.git' in root or 'scratch' in root:
                continue
            for f in files:
                if f.endswith('.xml'):
                    xml_files.append(os.path.join(root, f))

        self.assertTrue(len(xml_files) > 0, "At least one XML atlas must exist")

        for xml_path in xml_files:
            rel = os.path.relpath(xml_path, REPO_ROOT)
            try:
                tree = ET.parse(xml_path)
            except Exception as e:
                self.fail(f"XML parsing failed for {rel}: {e}")

            root = tree.getroot()
            self.assertEqual(root.tag, "Atlas", f"{rel} root tag must be <Atlas>")

            tex_elem = root.find("Texture")
            self.assertIsNotNone(tex_elem, f"{rel} must have <Texture> child")
            tex_filename = tex_elem.attrib.get("filename")
            self.assertTrue(tex_filename, f"{rel} <Texture> must specify filename")

            tex_file_path = os.path.join(os.path.dirname(xml_path), tex_filename)
            self.assertTrue(
                os.path.isfile(tex_file_path),
                f"{rel} references '{tex_filename}' which does not exist in {os.path.dirname(rel)}"
            )

            elements = root.find("Elements")
            if elements is not None:
                for elem in elements.findall("Element"):
                    name = elem.attrib.get("name")
                    u1 = float(elem.attrib.get("u1", 0.0))
                    u2 = float(elem.attrib.get("u2", 1.0))
                    v1 = float(elem.attrib.get("v1", 0.0))
                    v2 = float(elem.attrib.get("v2", 1.0))

                    self.assertTrue(0.0 <= u1 <= 1.0, f"{rel}:{name} u1={u1} out of bounds")
                    self.assertTrue(0.0 <= u2 <= 1.0, f"{rel}:{name} u2={u2} out of bounds")
                    self.assertTrue(0.0 <= v1 <= 1.0, f"{rel}:{name} v1={v1} out of bounds")
                    self.assertTrue(0.0 <= v2 <= 1.0, f"{rel}:{name} v2={v2} out of bounds")
                    self.assertTrue(u1 <= u2, f"{rel}:{name} u1 ({u1}) must be <= u2 ({u2})")
                    self.assertTrue(v1 <= v2, f"{rel}:{name} v1 ({v1}) must be <= v2 ({v2})")


class TestKtexTextures(unittest.TestCase):
    """Verifies all KTEX files have valid Klei magic headers and power-of-two dimensions."""

    def test_all_ktex_headers(self):
        tex_files = []
        for root, _, files in os.walk(REPO_ROOT):
            if '.git' in root or 'scratch' in root:
                continue
            for f in files:
                if f.endswith('.tex'):
                    tex_files.append(os.path.join(root, f))

        self.assertTrue(len(tex_files) > 0, "At least one .tex file must exist")

        for tex_path in tex_files:
            rel = os.path.relpath(tex_path, REPO_ROOT)
            with open(tex_path, 'rb') as f:
                header = f.read(18)

            self.assertTrue(len(header) >= 8, f"{rel} is too short to be a KTEX file")
            magic = header[:4]
            self.assertEqual(magic, b'KTEX', f"{rel} does not start with KTEX magic bytes")

            if len(header) >= 18:
                mw, mh = struct.unpack('<HH', header[8:12])
                if mw > 0 and mh > 0:
                    self.assertTrue(
                        (mw & (mw - 1)) == 0,
                        f"{rel} width {mw} is not a power of 2 (Klei requires power-of-two dimensions)"
                    )
                    self.assertTrue(
                        (mh & (mh - 1)) == 0,
                        f"{rel} height {mh} is not a power of 2 (Klei requires power-of-two dimensions)"
                    )


class TestAnimationArchives(unittest.TestCase):
    """Verifies all animation zip archives are non-corrupted and contain valid Klei binary files."""

    def test_all_anim_zips(self):
        anim_dir = os.path.join(REPO_ROOT, "anim")
        self.assertTrue(os.path.isdir(anim_dir), "anim directory must exist")

        zip_files = [f for f in os.listdir(anim_dir) if f.endswith('.zip')]
        self.assertTrue(len(zip_files) > 0, "anim directory must contain .zip files")

        for zname in zip_files:
            zpath = os.path.join(anim_dir, zname)
            self.assertTrue(zipfile.is_zipfile(zpath), f"{zname} is not a valid zip archive")

            with zipfile.ZipFile(zpath, 'r') as zf:
                # Test CRC-32 checksums of all entries
                bad_file = zf.testzip()
                self.assertIsNone(bad_file, f"Corrupted file inside {zname}: {bad_file}")

                names = zf.namelist()
                has_klei_content = any(n.endswith('.bin') or n.endswith('.tex') for n in names)
                self.assertTrue(has_klei_content, f"{zname} does not contain any .bin or .tex Klei anim data: {names}")


class TestSoundBanks(unittest.TestCase):
    """Verifies all sound files exist, have non-zero size, and contain valid FMOD headers."""

    def test_sound_bank_integrity(self):
        sound_dir = os.path.join(REPO_ROOT, "sound")
        self.assertTrue(os.path.isdir(sound_dir), "sound directory must exist")

        sound_files = os.listdir(sound_dir)
        self.assertTrue(len(sound_files) > 0, "sound directory must contain audio files")

        for sname in sound_files:
            spath = os.path.join(sound_dir, sname)
            size = os.path.getsize(spath)
            self.assertGreater(size, 0, f"Sound file {sname} is empty (0 bytes)!")

            with open(spath, 'rb') as fp:
                head = fp.read(8)

            if sname.endswith('.fsb'):
                # FMOD SoundBank magic
                self.assertIn(head[:4], (b'FSB4', b'FSB5'), f"{sname} does not have valid FSB magic bytes")
            elif sname.endswith('.fev'):
                # FMOD Event file starts with RIFF
                self.assertEqual(head[:4], b'RIFF', f"{sname} does not have RIFF magic bytes")


class TestArchitecturalStructure(unittest.TestCase):
    """Verifies prefabs, brains, stategraphs, and components follow proper Don't Starve conventions."""

    def test_all_prefabs_return_prefab(self):
        prefabs_dir = os.path.join(REPO_ROOT, "scripts", "prefabs")
        self.assertTrue(os.path.isdir(prefabs_dir), "scripts/prefabs must exist")

        for fname in os.listdir(prefabs_dir):
            if not fname.endswith('.lua'):
                continue
            fpath = os.path.join(prefabs_dir, fname)
            with open(fpath, 'r', encoding='utf-8', errors='ignore') as f:
                code = f.read()

            self.assertTrue(
                re.search(r'return\s+(Prefab|MakePlayerCharacter)\b', code),
                f"scripts/prefabs/{fname} must return Prefab(...) or MakePlayerCharacter(...) constructor"
            )

    def test_all_brains_return_class(self):
        brains_dir = os.path.join(REPO_ROOT, "scripts", "brains")
        if os.path.isdir(brains_dir):
            for fname in os.listdir(brains_dir):
                if fname.endswith('.lua'):
                    fpath = os.path.join(brains_dir, fname)
                    with open(fpath, 'r', encoding='utf-8', errors='ignore') as f:
                        code = f.read()
                    self.assertTrue(
                        re.search(r'return\s+\w+', code),
                        f"scripts/brains/{fname} must return a Brain class/object"
                    )

    def test_all_stategraphs_return_stategraph(self):
        sg_dir = os.path.join(REPO_ROOT, "scripts", "stategraphs")
        if os.path.isdir(sg_dir):
            for fname in os.listdir(sg_dir):
                if fname.endswith('.lua'):
                    fpath = os.path.join(sg_dir, fname)
                    with open(fpath, 'r', encoding='utf-8', errors='ignore') as f:
                        code = f.read()
                    if fname == "SGcritter_common.lua":
                        self.assertIn("SGCritterEvents", code)
                        self.assertIn("SGCritterStates", code)
                    else:
                        self.assertTrue(
                            re.search(r'return\s+StateGraph\b', code),
                            f"scripts/stategraphs/{fname} must return StateGraph(...)"
                        )

    def test_all_components_return_table(self):
        comp_dir = os.path.join(REPO_ROOT, "scripts", "components")
        if os.path.isdir(comp_dir):
            for fname in os.listdir(comp_dir):
                if fname.endswith('.lua'):
                    fpath = os.path.join(comp_dir, fname)
                    with open(fpath, 'r', encoding='utf-8', errors='ignore') as f:
                        code = f.read()
                    self.assertTrue(
                        re.search(r'return\s+\w+', code),
                        f"scripts/components/{fname} must return a component class/table"
                    )


class TestRepositoryCleanliness(unittest.TestCase):
    """Verifies that no merge conflicts or accidental temporary artifacts exist in the repository."""

    def test_no_git_conflict_markers(self):
        conflict_re = re.compile(r'^(<{7}|={7}|>{7})(\s|$)', re.MULTILINE)
        for root, _, files in os.walk(REPO_ROOT):
            if '.git' in root or 'scratch' in root or '.system_generated' in root:
                continue
            for f in files:
                ext = os.path.splitext(f)[1].lower()
                if ext in ('.lua', '.xml', '.md', '.txt', '.json', '.yml', '.yaml'):
                    fpath = os.path.join(root, f)
                    with open(fpath, 'r', encoding='utf-8', errors='ignore') as fp:
                        content = fp.read()
                    rel = os.path.relpath(fpath, REPO_ROOT)
                    self.assertIsNone(
                        conflict_re.search(content),
                        f"Found Git merge conflict marker in {rel}!"
                    )


class TestRuntimeSafetyAndSpawnCalls(unittest.TestCase):
    """Verifies runtime safety: SpawnPrefab targets valid prefabs, no unsafe nil chaining, and UI strings exist."""

    def test_spawnprefab_targets_are_valid(self):
        """Ensure all SpawnPrefab calls reference known mod prefabs or valid vanilla Don't Starve prefabs."""
        modmain_path = os.path.join(REPO_ROOT, "modmain.lua")
        with open(modmain_path, 'r', encoding='utf-8') as f:
            modmain_code = f.read()

        match = re.search(r'PrefabFiles\s*=\s*\{([^}]+)\}', modmain_code)
        mod_prefabs = set(re.findall(r'"([^"]+)"', match.group(1))) if match else set()

        vanilla_prefabs = {
            "sparks_fx", "statue_transition", "impact", "critter_kitten",
            "cane_ancient_fx", "cane_victorian_fx", "shatter", "statue_transition_2"
        }
        known_prefabs = mod_prefabs | vanilla_prefabs

        spawn_re = re.compile(r'SpawnPrefab\(\s*"([^"]+)"\s*\)')

        for root, _, files in os.walk(REPO_ROOT):
            if '.git' in root or 'scratch' in root or 'tests' in root:
                continue
            for f in files:
                if f.endswith('.lua'):
                    fpath = os.path.join(root, f)
                    with open(fpath, 'r', encoding='utf-8', errors='ignore') as fp:
                        code = fp.read()
                    rel = os.path.relpath(fpath, REPO_ROOT)
                    for m in spawn_re.finditer(code):
                        prefab_name = m.group(1)
                        self.assertIn(
                            prefab_name,
                            known_prefabs,
                            f"In {rel}: SpawnPrefab('{prefab_name}') references unknown prefab (potential crash)!"
                        )

    def test_no_unsafe_spawnprefab_chaining(self):
        """Ensure no code does SpawnPrefab(...).Transform without a nil check, which crashes if spawn fails."""
        unsafe_chain_re = re.compile(r'SpawnPrefab\([^)]+\)\.(Transform|components|entity|Physics|AnimState)\b')

        for root, _, files in os.walk(REPO_ROOT):
            if '.git' in root or 'scratch' in root or 'tests' in root:
                continue
            for f in files:
                if f.endswith('.lua'):
                    fpath = os.path.join(root, f)
                    with open(fpath, 'r', encoding='utf-8', errors='ignore') as fp:
                        for lno, line in enumerate(fp, 1):
                            clean_line = line.split('--')[0].strip()
                            self.assertIsNone(
                                unsafe_chain_re.search(clean_line),
                                f"{os.path.relpath(fpath, REPO_ROOT)}:{lno}: Unsafe direct chaining on SpawnPrefab! Store in variable and guard with 'if inst then'."
                            )

    def test_character_and_item_strings_exist(self):
        """Ensure all prefabs in PrefabFiles have display names in STRINGS.NAMES so they don't show MISSING NAME or crash."""
        modmain_path = os.path.join(REPO_ROOT, "modmain.lua")
        with open(modmain_path, 'r', encoding='utf-8') as f:
            modmain_code = f.read()

        match = re.search(r'PrefabFiles\s*=\s*\{([^}]+)\}', modmain_code)
        mod_prefabs = re.findall(r'"([^"]+)"', match.group(1)) if match else []

        for prefab in mod_prefabs:
            if prefab in ("light_projectile",):
                continue
            upper_name = prefab.upper()
            found = (
                f"NAMES.{upper_name}" in modmain_code or
                f"NAMES.{prefab}" in modmain_code or
                f'STRINGS.NAMES["{upper_name}"]' in modmain_code or
                f'STRINGS.NAMES["{prefab}"]' in modmain_code
            )
            self.assertTrue(
                found,
                f"Prefab '{prefab}' declared in PrefabFiles should have STRINGS.NAMES.{upper_name} defined in modmain.lua"
            )

    def _all_mod_lua(self):
        for root, _, files in os.walk(REPO_ROOT):
            if '.git' in root or 'scratch' in root or 'tests' in root:
                continue
            for f in files:
                if f.endswith('.lua'):
                    fpath = os.path.join(root, f)
                    with open(fpath, 'r', encoding='utf-8', errors='ignore') as fp:
                        yield os.path.relpath(fpath, REPO_ROOT), fp.read()

    def test_removed_features_are_gone(self):
        """Hoki and the Traveler's Pack must not be registered or spawned anywhere."""
        for name in ("hoki.lua", "elena_pack.lua"):
            self.assertFalse(os.path.isfile(os.path.join(REPO_ROOT, "scripts", "prefabs", name)), f"{name} should be removed")
        for rel, code in self._all_mod_lua():
            self.assertFalse('"hoki"' in code, f"{rel} still references the hoki prefab")
            self.assertFalse('"elena_pack"' in code, f"{rel} still references elena_pack")

    def test_no_dst_only_entity_tags(self):
        """_combat / _inventoryitem tags only exist in DST; in DS such searches silently find nothing."""
        for rel, code in self._all_mod_lua():
            for tag in ('"_combat"', '"_inventoryitem"', "{'combat'}"):
                self.assertFalse(tag in code, f"{rel} searches for DST-only tag {tag}")

    def test_no_undeclared_dst_globals(self):
        """DS runs with strict globals: reading a global that doesn't exist crashes the game."""
        for rel, code in self._all_mod_lua():
            self.assertFalse("TileGroupManager" in code, f"{rel} reads the DST-only global TileGroupManager")

    def test_floatable_helper_is_guarded(self):
        """MakeInventoryFloatable only exists with the SW/Hamlet scripts; call it through elena_util."""
        for rel, code in self._all_mod_lua():
            if rel.endswith("elena_util.lua"):
                continue
            self.assertFalse("MakeInventoryFloatable(" in code, f"{rel} calls MakeInventoryFloatable directly")

    def test_no_missing_sound_events(self):
        """These events don't exist in DS and were logged as FMOD errors."""
        missing = ("dontstarve/common/staff\"", "wendy/emote", "abigail/level_up", "lava_arena")
        for rel, code in self._all_mod_lua():
            for snd in missing:
                self.assertFalse(snd in code, f"{rel} plays missing sound {snd}")

    def test_potions_safe_for_non_player_eaters(self):
        """Pigs and birds eat potions off the ground and have no sanity component."""
        for name in ("potion_magic.lua", "potion_sourceliquid.lua"):
            with open(os.path.join(REPO_ROOT, "scripts", "prefabs", name), encoding="utf-8") as f:
                code = f.read()
            self.assertNotIn("eater.components.sanity:DoDelta", code, f"{name} assumes the eater has sanity")

    def test_frost_elixir_checks_weapon(self):
        """Holding an umbrella or lantern (no weapon component) used to crash the Frost Elixir."""
        with open(os.path.join(REPO_ROOT, "scripts", "prefabs", "potion_icepowder.lua"), encoding="utf-8") as f:
            code = f.read()
        self.assertNotIn("onarm.components.weapon", code)
        self.assertIn("if not weapon then", code)

    def test_level_damage_bonus_is_additive(self):
        """SW/Hamlet damage modifiers are summed; adding 1 + bonus doubled Elaina's damage."""
        with open(os.path.join(REPO_ROOT, "scripts", "components", "level.lua"), encoding="utf-8") as f:
            code = f.read()
        self.assertNotIn("1 + (bonus_ratio", code)


if __name__ == '__main__':
    unittest.main(verbosity=2)

