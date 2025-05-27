# 使用 llama.cpp 转 GGUF 格式

微调后的模型，需要转为 GGUF 格式，需要使用 `llama.cpp` 的项目中的 python 脚本。

==⚠️ 这里只用于转 GGUF 格式，因此编译 llama.cpp 时禁用了 CUDA/GPU 支持。==

## JupyterLab 笔记方式

在 JupyterLab 下的执行脚本：

```bash
# 安装编译需要的工具和库
!apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    cmake \
    build-essential

# 获取 llama.cpp 源代码
!git clone --depth 1 https://github.com/ggml-org/llama.cpp.git

# 编译基于 cpu 的 llama.cpp 轻量级静态库
!cd ./llama.cpp  && \
    mkdir build && \
    cd build && \
    cmake .. \
      -DLLAMA_CUBLAS=OFF \
      -DLLAMA_CURL=OFF \
      -DLLAMA_OPENBLAS=OFF \
      -DLLAMA_METAL=OFF \
      -DBUILD_SHARED_LIBS=OFF && \
    cmake --build . --config Release -j $(nproc)

# 执行脚本所需的 python 依赖库
%pip install -qU numpy transformers sentencepiece 
%pip install -qU torch==2.6.0 --index-url https://download.pytorch.org/whl/cpu

# 将 ./merged_model 的 hf 格式模型转为 GGUF 格式的 ./gguf_model
!python ./llama.cpp/convert_hf_to_gguf.py \
    ./merged_model --outfile ./gguf_model --outtype f16
```

## Docker 镜像方式

构建 Docker 镜像：

```bash
docker build -t llama-cpp-converter .
```

使用：

```bash
# 查看命令的帮助
docker run -it --rm llama-cpp-converter

usage: convert_hf_to_gguf.py [-h] [--vocab-only] [--outfile OUTFILE] [--outtype {f32,f16,bf16,q8_0,tq1_0,tq2_0,auto}] [--bigendian] [--use-temp-file] [--no-lazy] [--model-name MODEL_NAME]
                             [--verbose] [--split-max-tensors SPLIT_MAX_TENSORS] 
。。。

# 执行命令转换生成 GGUF 模型
docker run -it --rm \
	-v /mnt/data:/data \
	llama-cpp-converter \
	/data/merged_model \
    --outfile /data/gguf-model.gguf \
	--outtype f16

```

也可以进入容器调试使用：

```bash
# 进入容器的 bash
docker run -it --rm \
	-v /mnt/data:/data \
	-e DEBUG=true llama-cpp-converter

# 在容器 bash 执行脚本
python ./convert_hf_to_gguf.py /data/merged_model \
	--outfile /data/gguf-model.gguf \
	--outtype f16
```
