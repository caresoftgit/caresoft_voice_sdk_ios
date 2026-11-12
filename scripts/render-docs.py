from pathlib import Path
import markdown
import os
os.chdir(Path(__file__).resolve().parents[1])
source=Path('docs/ios-integration-guide.md')
body=markdown.markdown(source.read_text(),extensions=['tables','fenced_code','toc'],output_format='html5')
style='''
:root{color-scheme:light;--ink:#18243b;--muted:#526079;--brand:#3d55cc;--line:#dfe4ee}
*{box-sizing:border-box}html{scroll-padding-top:32px}
body{margin:0;background:#f3f5fa;color:var(--ink);font:16px/1.75 -apple-system,BlinkMacSystemFont,"Segoe UI",Arial,sans-serif}
main{max-width:1120px;margin:32px auto;padding:48px 64px;background:#fff;border:1px solid var(--line);border-radius:16px}
h1{font-size:38px;line-height:1.22;letter-spacing:-.6px;color:#22358c;margin:0 0 28px}
h2{font-size:27px;line-height:1.35;margin:54px 0 20px;padding-top:20px;border-top:2px solid #e7ebf7;color:#253d9a}
h3{font-size:21px;margin:30px 0 12px}p{margin:12px 0}a{color:#2848b9;text-decoration:none}a:hover{text-decoration:underline}
ul,ol{padding-left:26px}li{margin:7px 0}strong{font-weight:650}table{width:100%;border-collapse:collapse;margin:20px 0;font-size:14px;table-layout:auto}
th,td{text-align:left;vertical-align:top;border:1px solid var(--line);padding:11px 13px;overflow-wrap:anywhere}th{background:#eef1fb;color:#263981}
tr:nth-child(even){background:#fafbfe}code{font:13px/1.6 "SFMono-Regular",Consolas,monospace;background:#eef1f7;padding:2px 5px;border-radius:4px;overflow-wrap:anywhere}
pre{padding:20px;background:#17243b;color:#edf3ff;border-radius:9px;overflow-x:auto;line-height:1.65}pre code{padding:0;background:transparent;color:inherit;white-space:pre;overflow-wrap:normal}
footer{margin-top:48px;padding-top:18px;border-top:1px solid var(--line);font-size:13px;color:var(--muted)}
@media(max-width:760px){main{margin:0;padding:28px 18px;border:0;border-radius:0}h1{font-size:29px}h2{font-size:24px}table{font-size:12px}th,td{padding:7px}pre{padding:14px}}
@media print{body{background:white;font-size:10pt;line-height:1.5}main{max-width:none;margin:0;padding:0;border:0}h1{font-size:26pt}h2{font-size:18pt;break-before:page;border:0;padding:0;margin:12px 0}h3{font-size:13pt;break-after:avoid}pre{white-space:pre-wrap;background:#f3f5f9;color:#18243b;border:1px solid #dfe4ee;font-size:8pt;padding:10px}pre code{white-space:pre-wrap;font-size:8pt;overflow-wrap:anywhere}table{font-size:9pt}thead{display:table-header-group}tr{break-inside:avoid}a{color:inherit;text-decoration:none}footer{font-size:8pt}@page{size:A4;margin:17mm}}
'''
html='<!doctype html><html lang="vi"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Caresoft Voice SDK — Tích hợp iOS native</title><style>'+style+'</style></head><body><main>'+body+'<footer>Caresoft Voice SDK · iOS native · 1.1.0 · 12/11/2026</footer></main></body></html>'
Path('docs/caresoft-voice-ios.html').write_text(html)
print('Rendered HTML:',len(html),'characters')
