"""Verify and extract the bundled SDK. Run after cloning this repository."""
from pathlib import Path, PurePosixPath
import hashlib
import shutil
import tempfile
import zipfile

packages = Path(__file__).resolve().parents[1] / 'packages'
checksum, name = (packages / 'SHA256SUMS').read_text().strip().split()
assert Path(name).name == name, 'Invalid archive name'
archive = packages / name
assert hashlib.sha256(archive.read_bytes()).hexdigest() == checksum, 'SDK checksum mismatch'
with tempfile.TemporaryDirectory(dir=packages) as temporary:
    stage = Path(temporary)
    with zipfile.ZipFile(archive) as z:
        for member in z.infolist():
            path = PurePosixPath(member.filename)
            assert not path.is_absolute() and '..' not in path.parts and path.parts[0] == 'CaresoftVoice', 'Unsafe archive path'
            assert (member.external_attr >> 16) & 0o170000 != 0o120000, 'Symlinks are not supported'
        z.extractall(stage)
    sdk = stage / 'CaresoftVoice'
    for required in ['Package.swift', 'CaresoftVoice.xcframework/Info.plist', 'WebRTC.xcframework/Info.plist']:
        assert (sdk / required).is_file(), f'Missing {required}'
    target = packages / 'CaresoftVoice'
    if target.exists():
        shutil.rmtree(target)
    shutil.move(str(sdk), target)
print('Verified SHA-256 and installed packages/CaresoftVoice')
