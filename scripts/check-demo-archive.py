"""Validate the demo archive's App Store icon, iPad and WebRTC symbol requirements."""
from pathlib import Path
import plistlib, re, subprocess, sys

archive = Path(sys.argv[1])
metadata = plistlib.loads((archive / 'Info.plist').read_bytes())['ApplicationProperties']
app = archive / 'Products' / metadata['ApplicationPath']
info = plistlib.loads((app / 'Info.plist').read_bytes())
assert info.get('CFBundleIconName') == 'AppIcon', 'Missing CFBundleIconName'
assert info.get('VoicePushEnvironment') == 'production', 'TestFlight voice push environment must be production'
for key in ['NSMicrophoneUsageDescription', 'NSCameraUsageDescription']:
    assert isinstance(info.get(key), str) and info[key].strip(), f'Missing purpose string: {key}'
for key in ['CFBundleIcons', 'CFBundleIcons~ipad']:
    assert info[key]['CFBundlePrimaryIcon']['CFBundleIconName'] == 'AppIcon', key
sizes = set()
for png in app.glob('AppIcon*.png'):
    output = subprocess.check_output(['sips', '-g', 'pixelWidth', '-g', 'pixelHeight', str(png)], text=True)
    sizes.add(tuple(int(re.search(key + r': (\d+)', output).group(1)) for key in ['pixelWidth', 'pixelHeight']))
assert {(120, 120), (152, 152)} <= sizes, f'Missing required icons: {sizes}'
orientations = info.get('UISupportedInterfaceOrientations~ipad', info.get('UISupportedInterfaceOrientations', []))
assert info.get('UIRequiresFullScreen') is True or {
    'UIInterfaceOrientationPortrait', 'UIInterfaceOrientationPortraitUpsideDown',
    'UIInterfaceOrientationLandscapeLeft', 'UIInterfaceOrientationLandscapeRight'
} <= set(orientations), 'iPad multitasking orientation requirements not met'

def uuids(path):
    result = subprocess.check_output(['xcrun', 'dwarfdump', '--uuid', str(path)], text=True)
    matches = set(re.findall(r'UUID: ([A-Fa-f0-9-]+) \(([^)]+)\)', result))
    assert matches, f'No UUIDs: {path}'
    return matches
binary = app / 'Frameworks/WebRTC.framework/WebRTC'
symbols = archive / 'dSYMs/WebRTC.dSYM/Contents/Resources/DWARF/WebRTC'
assert uuids(binary) == uuids(symbols), 'WebRTC dSYM UUID mismatch'
assert not list((archive / 'Products').rglob('*.xctest')), 'Archive contains tests'
subprocess.run(['codesign', '--verify', '--deep', '--strict', str(app)], check=True)
print(f"PASS: {info['CFBundleIdentifier']} {info['CFBundleShortVersionString']} ({info['CFBundleVersion']}); icons 120/152, iPad, WebRTC dSYM and signature")
