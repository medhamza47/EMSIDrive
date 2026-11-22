"""Repack safetensors into layer shards without decoding or changing any weight."""
import pathlib,json,struct,re,shutil
root=pathlib.Path('/models/PaddleOCR-VL-1.6');target=root.with_name(root.name+'-sharded');target.mkdir(exist_ok=True)
source=root/'model.safetensors'
with source.open('rb') as f:
    n=struct.unpack('<Q',f.read(8))[0];header=json.loads(f.read(n));data_start=8+n
    groups={}
    for key,value in header.items():
        if key=='__metadata__':continue
        match=re.match(r'(.*?(?:layers|blocks)\.\d+)\.',key)
        group=match[1] if match else key.split('.')[0]
        groups.setdefault(group,[]).append(key)
    index={'metadata':{'total_size':sum(v['data_offsets'][1]-v['data_offsets'][0] for k,v in header.items() if k!='__metadata__')},'weight_map':{}}
    for number,(group,keys) in enumerate(sorted(groups.items()),1):
        name=f'model-{number:05d}-of-{len(groups):05d}.safetensors';out_header={};offset=0
        if '__metadata__' in header:out_header['__metadata__']=header['__metadata__']
        for key in keys:
            info=header[key].copy();a,b=info['data_offsets'];size=b-a;info['data_offsets']=[offset,offset+size];offset+=size;out_header[key]=info;index['weight_map'][key]=name
        raw=json.dumps(out_header,separators=(',',':')).encode();raw+=b' '*((-len(raw))%8)
        with (target/name).open('wb') as out:
            out.write(struct.pack('<Q',len(raw)));out.write(raw)
            for key in keys:
                a,b=header[key]['data_offsets'];f.seek(data_start+a);remaining=b-a
                while remaining:
                    chunk=f.read(min(1024*1024,remaining))
                    if not chunk:raise RuntimeError('Truncated input weights')
                    out.write(chunk);remaining-=len(chunk)
        print(name,group,offset,flush=True)
    for p in root.iterdir():
        if p.is_file() and p.suffix!='.safetensors':shutil.copy2(p,target/p.name)
    (target/'model.safetensors.index.json').write_text(json.dumps(index))
print('LOSSLESS SHARDING COMPLETE',flush=True)
