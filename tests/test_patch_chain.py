"""Static regression gates for the canonical SnakeGame Command Bar patches.

These tests DO NOT execute Roblox Engine services or simulate Studio gameplay.
Run: python -m unittest discover -s tests -v
"""
from __future__ import annotations

import ast
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
UPDATES = ROOT / "updates"
CANONICAL = [
    "0001_bootstrap_solo.lua",
    "0002_solo_isolation.lua",
    "0003_independent_solo_arenas.lua",
    "0004_solo_client_polish.lua",
    "0005_mobile_swipe_controls.lua",
    "0006_remote_input_guard.lua",
    "0007_restart_input_fix.lua",
    "0008_mode_command_compat.lua",
    "0009_full_board_win.lua",
    "0010_circular_mode_integration.lua",
    "0011_hud_explorer_after_circular.lua",
    "0012_adaptive_mobile_swipe.lua",
    "0013_swipe_text_focus_guard.lua",
    "0014_swipe_focus_lifecycle.lua",
    "0015_swipe_window_focus.lua",
    "0016_server_validated_skins.lua",
    "0017_camera_focus_solo_floor.lua",
    "0018_server_render_cache.lua",
    "0019_render_cache_recovery.lua",
]


def source(index: int) -> str:
    return (UPDATES / CANONICAL[index - 1]).read_text(encoding="utf-8")


def bootstrap_script(variable: str) -> str:
    match = re.search(
        rf'^local {re.escape(variable)}="((?:\\.|[^"\\])*)"',
        source(1),
        re.MULTILINE,
    )
    if match is None:
        raise AssertionError(f"0001: embedded source {variable} missing")
    return ast.literal_eval('"' + match.group(1) + '"')


class CanonicalPatchTests(unittest.TestCase):
    def test_exactly_one_patch_per_number(self) -> None:
        actual = sorted(p.name for p in UPDATES.glob("*.lua"))
        self.assertEqual(actual, CANONICAL)
        numbers = [int(n[:4]) for n in actual]
        self.assertEqual(numbers, list(range(1, 20)))

    def test_nonempty_and_marked(self) -> None:
        for i in range(2, 20):
            with self.subTest(patch=i):
                code = source(i)
                self.assertGreater(len(code), 100)
                self.assertIn(f"-- SnakeGame {i:04d} applied", code)
                self.assertIn("rollback", code.lower())
                self.assertIn("Source", code)

    def test_bootstrap_embedded_sources(self) -> None:
        server = bootstrap_script("serverSource")
        client = bootstrap_script("clientSource")
        self.assertIn('turn.OnServerEvent:Connect', server)
        self.assertIn('local function reset(player)', server)
        self.assertIn('local function paint(s)', server)
        self.assertIn('local gui=Instance.new("ScreenGui")', client)
        self.assertIn('local keys={', client)
        self.assertIn('camera.CFrame=CFrame.lookAt(', client)

    def test_baseline_anchors_for_first_patches(self) -> None:
        server = bootstrap_script("serverSource")
        client = bootstrap_script("clientSource")
        for anchor in (
            'local sessions = {}',
            'local function key(v) return tostring(v.X)..":"..tostring(v.Y) end',
            'local reference=s.pending or s.dir',
            'local model=Instance.new("Model"); model.Name="Snake_"..player.UserId; model.Parent=arena',
            'score=s.score,alive=s.alive,body=s.body',
            'if not s.food then s.alive=false end',
            'if typeof(command)~="string" then return end',
        ):
            with self.subTest(anchor=anchor):
                self.assertEqual(server.count(anchor), 1)
        for anchor in (
            'local gui=Instance.new("ScreenGui")',
            'camera.CFrame=CFrame.lookAt(Vector3.new(0,90,65),Vector3.new(0,0,0))',
            'local keys={',
        ):
            with self.subTest(anchor=anchor):
                self.assertEqual(client.count(anchor), 1)

    def test_remote_input_evolution(self) -> None:
        guard, compat, circular = source(6), source(8), source(10)
        self.assertIn('#command > 7', guard)
        self.assertIn('directions[command]==nil', guard)
        self.assertIn('#command > 12', compat)
        self.assertIn('command=="ModeClassic" or command=="ModeCircular"', compat)
        self.assertIn('if isModeCommand and not hasModeHandler then return end', compat)
        # 0008 installs false if 0010 has not yet created a mode handler;
        # 0010 MUST explicitly change this to true.
        self.assertIn("'local hasModeHandler = false'", circular)
        self.assertIn("'local hasModeHandler = true'", circular)
        self.assertIn('0010 postcheck: filtro de modos', circular)

    def test_no_victory_regression_in_circular_line(self) -> None:
        win, circular, hud = source(9), source(10), source(11)
        self.assertIn('s.won=true', win)
        self.assertIn('s.won==true', win)
        self.assertIn('won=s.won==true,body=s.body', circular)
        self.assertIn('won=false,model=model', circular)
        self.assertIn('s.won==true', hud)
        self.assertNotIn('score=s.score,alive=s.alive,body=s.body,food=s.food,step=STEP,mode=s.mode"', circular)

    def test_circular_server_authority(self) -> None:
        circular = source(10)
        for anchor in (
            'validCell(s.mode,head)',
            'validCell(s.mode,v)',
            'CIRCLE_RADIUS_CELLS',
            'ModeCircular',
            'lastModeSwitch',
            'local hasModeHandler = true',
            'SnakeGameModeSelect',
        ):
            with self.subTest(anchor=anchor):
                self.assertIn(anchor, circular)

    def test_hud_explorer_and_mobile_guards(self) -> None:
        hud, swipe, typing, focus, window = (source(i) for i in range(11, 16))
        self.assertIn('StarterGui', hud)
        self.assertIn('gui:WaitForChild("Score")', hud)
        self.assertIn('SnakeGameModeSelect', hud)
        self.assertIn('swipeThreshold()', swipe)
        self.assertIn('GetFocusedTextBox()', typing)
        self.assertIn('TextBoxFocused', focus)
        self.assertIn('WindowFocusReleased', window)
        self.assertIn('swipeFinger = nil', window)

    def test_skin_selection_server_whitelist(self) -> None:
        skins = source(16)
        for anchor in (
            'skinCommands={SkinClassic="Classic",SkinEmber="Ember",SkinFrost="Frost"}',
            'skinCommands[command]',
            'lastSkinSwitch',
            's.skin=desiredSkin',
            'skinPalettes[s.skin]',
            'SkinEmber',
            'SkinFrost',
        ):
            with self.subTest(anchor=anchor):
                self.assertIn(anchor, skins)

    def test_camera_and_cache_are_independent_targets(self) -> None:
        camera, cache = source(17), source(18)
        self.assertIn('client.Source=revised', camera)
        self.assertNotIn('server.Source=revised', camera)
        self.assertIn('server.Source=revised', cache)
        self.assertNotIn('client.Source=revised', cache)
        self.assertIn('camera.Focus=CFrame.new(target)', camera)
        self.assertIn('LocalTransparencyModifier', camera)

    def test_cache_recovery_guards(self) -> None:
        repair = source(19)
        self.assertIn("p.Parent~=segments", repair)
        self.assertIn("food.Parent~=model", repair)
        self.assertIn("segmentParts[i]=nil", repair)
        self.assertIn("s.foodPart=nil", repair)
        self.assertIn("server.Source=old", repair)
        self.assertIn("server.Source==nextSource", repair)
        self.assertIn("-- SnakeGame 0018 applied", repair)

    def test_render_cache_ref_lifecycle(self) -> None:
        cache = source(18)
        for anchor in (
            's.segmentParts',
            's.foodPart',
            'segmentParts[i]=p',
            'segmentParts[i]=nil',
            's.foodPart=nil',
            'skinPalettes[s.skin]',
        ):
            with self.subTest(anchor=anchor):
                self.assertIn(anchor, cache)


if __name__ == "__main__":
    unittest.main()
