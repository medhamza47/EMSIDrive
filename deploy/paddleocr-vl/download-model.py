import json, urllib.request, pathlib, time
repo='PaddlePaddle/PaddleOCR-VL-1.6'
root=pathlib.Path('/models/PaddleOCR-VL-1.6');root.mkdir(parents=True,exist_ok=True)
api='https://huggingface.co/api/models/'+repo
with urllib.request.urlopen(api,timeout=60) as r: meta=json.load(r)
revision=meta['sha']
(root/'download-revision.txt').write_text(revision)
for entry in meta['siblings']:
    name=entry['rfilename']
    if name.startswith('.') or name.endswith('.md'):continue
    dest=root/name
    if dest.exists() and dest.stat().st_size>0:continue
    dest.parent.mkdir(parents=True,exist_ok=True)
    url='https://huggingface.co/'+repo+'/resolve/'+revision+'/'+name
    for attempt in range(5):
        try:
            print('Downloading '+name,flush=True)
            with urllib.request.urlopen(url,timeout=120) as src, open(str(dest)+'.partial','wb') as out:
                count=0;last=0
                while True:
                    chunk=src.read(1024*1024)
                    if not chunk:break
                    out.write(chunk);count+=len(chunk)
                    if count-last>=50*1024*1024:print(name+': '+str(count//1048576)+' MB',flush=True);last=count
            pathlib.Path(str(dest)+'.partial').replace(dest)
            print('Completed '+name,flush=True);break
        except Exception as error:
            print(str(error),flush=True)
            if attempt==4:raise
            time.sleep(5)
print('MODEL DOWNLOAD COMPLETE',flush=True)
