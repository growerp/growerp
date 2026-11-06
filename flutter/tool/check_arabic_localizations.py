"""Static ARB and integration checks, not a substitute for Flutter/UI tests."""
import json
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
packages = root / 'packages'
checked = 0
for source in sorted(packages.glob('*/lib/l10n/*_en.arb')):
    target = source.with_name(source.name.replace('_en.arb', '_ar.arb'))
    en = json.loads(source.read_text())
    ar = json.loads(target.read_text())
    assert ar['@@locale'] == 'ar', target
    for key, value in ar.items():
        if key.startswith('@'):
            continue
        assert key in en, (target, key)
        assert isinstance(value, str) and value.strip(), (target, key)
        placeholders = en.get('@' + key, {}).get('placeholders', {})
        for placeholder in placeholders:
            assert re.search(r'\{' + re.escape(placeholder) + r'\s*[,}]', value), (target, key, placeholder)
    if source.name == 'core_en.arb':
        assert {k for k in en if not k.startswith('@')} == {k for k in ar if not k.startswith('@')}
    config = source.parents[2] / 'l10n.yaml'
    assert re.search(r'preferred-supported-locales:.*\bar\b', config.read_text()), config
    checked += 1
core = packages / 'growerp_core/lib/src/domains/common'
assert "Locale('ar')" in (core / 'widgets/top_app.dart').read_text()
assert "'العربية'" in (core / 'views/home_form.dart').read_text()
assert 'GlobalWidgetsLocalizations.delegate' in (core / 'widgets/top_app.dart').read_text()
print(f'PASS: {checked} Arabic ARB resources, placeholder references, core key coverage, locale registration and selector.')
