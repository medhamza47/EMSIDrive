# Bundled PaddleOCR Android SDK

Source: https://github.com/PaddlePaddle/PaddleOCR

Pinned source revision: `dab3fe35379033fdcb2d0e9572fac0b36c9a9ebf`.
The files under `src/main/java/com/paddle/ocr` are upstream SDK sources.
The Gradle configuration is adapted to this Flutter project, with OpenCV 4.12.0
and ONNX Runtime 1.27.0 for modern Android compatibility. Apache-2.0 license
and upstream source headers are preserved in this directory.

Bundled models are the official **PP-OCRv6 Small**, not the 0.9B PaddleOCR-VL
model. Both inference and geometric timetable reconstruction run on Android.
No document, text or model inference is sent to a server in phone analysis mode.
Saving a reviewed schedule still uses the authenticated EMSIDrive API.

Model archives:

- https://paddle-model-ecology.bj.bcebos.com/paddlex/official_inference_model/paddle3.0.0/PP-OCRv6_small_det_onnx_infer.tar
- https://paddle-model-ecology.bj.bcebos.com/paddlex/official_inference_model/paddle3.0.0/PP-OCRv6_small_rec_onnx_infer.tar

Unpacked ONNX model checksums (SHA-256):

- Detection: `d73e0058b7a8086bbd57f3d10b8bcd4ff95363f67e06e2762b5e814fe9c9410e`
- Recognition: `5435fd747c9e0efe15a96d0b378d5bd157e9492ed8fd80edf08f30d02fa24634`

The model files total 31,039,890 bytes; the runtime, native libraries and
recognition dictionary add to the installed application size. Android 8.0+
(API 26+) is required by this SDK.

The ported grid detector in the app is derived from EMSIDrive's existing server
detector. The Dart parser uses measured cell spans, preserves printed course
time overrides, and leaves an unknown end time empty when geometry is unclear.
Users must review and confirm the result. The online import path remains
selectable and is never invoked automatically by the phone analysis path.
