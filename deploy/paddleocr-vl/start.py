import os
os.environ.setdefault("FLAGS_paddle_num_threads", "8")
import pathlib, subprocess, yaml, paddlex
root=pathlib.Path(paddlex.__file__).parent
predictor=root/'inference/models/doc_vlm/predictor.py'
text=predictor.read_text().replace('low_cpu_mem_usage=True,','low_cpu_mem_usage=False,')
predictor.write_text(text)
paths=root/'inference/models/utils/model_paths.py'
text=paths.read_text()
if 'model.safetensors.index.json' not in text:
    text=text.replace('    return model_paths','    if (model_dir / "model.safetensors.index.json").exists():\n        model_paths["safetensors"] = model_dir / "model.safetensors.index.json"\n    return model_paths')
    paths.write_text(text)
model_code=root/'inference/models/doc_vlm/modeling/paddleocr_vl/_paddleocr_vl.py'
text=model_code.read_text()
old='assert std_state_dict.keys() == state_dict.keys()\n        for key in std_state_dict:'
new='assert set(state_dict).issubset(std_state_dict)\n        loaded = getattr(self, "_emsidrive_loaded_keys", set())\n        loaded.update(state_dict)\n        self._emsidrive_loaded_keys = loaded\n        for key in state_dict:'
if old in text: model_code.write_text(text.replace(old,new))
text=predictor.read_text()
check='        return model, processor'
if '_emsidrive_loaded_keys' not in text:
    text=text.replace(check,'        if hasattr(model, "_emsidrive_loaded_keys"):\n            assert model._emsidrive_loaded_keys == set(model.state_dict()), "Incomplete sharded checkpoint"\n'+check)
    predictor.write_text(text)
source=root/'configs/pipelines/PaddleOCR-VL-1.6.yaml'
config=yaml.safe_load(source.read_text())
model=pathlib.Path('/models/PaddleOCR-VL-1.6-sharded')
if not (model/'model.safetensors.index.json').is_file():
    raise RuntimeError('Download the PaddleOCR-VL-1.6 model before starting the service')
config['batch_size']=1
config['SubModules']['VLRecognition']['model_dir']=str(model)
config['SubModules']['VLRecognition']['batch_size']=1
config['SubModules']['VLRecognition']['engine']='paddle_dynamic'
config['SubModules']['LayoutDetection']['batch_size']=1
path=pathlib.Path('/tmp/emsidrive-pipeline.yaml')
path.write_text(yaml.safe_dump(config))
subprocess.run(['paddlex','--serve','--pipeline',str(path),'--device','cpu','--host','0.0.0.0','--port','8080'],check=True)
