struct BufferCreator:
    @staticmethod
    fn _create_uniform_buffer(device: wgpu.Device, size: Int) -> ArcPointer[wgpu.Buffer]:
        buffer = ArcPointer(
            device.create_buffer(
                BufferDescriptor(
                    "uniform buffer",
                    BufferUsage.uniform | BufferUsage.copy_dst,
                    sizeof[Float32](),
                    True,
                )
            )
        )
        uniform_dst = buffer[].get_mapped_range(0, size).bitcast[Float32]()
        uniform_dst[0] = 0
        buffer[].unmap()
        return buffer

    @staticmethod
    fn _create_vertex_buffer(device: wgpu.Device, vertices: List[MyVertex]) -> ArcPointer[wgpu.Buffer]:
        vertices_size_bytes = len(vertices) * sizeof[MyVertex]()
        buffer = ArcPointer(device.create_buffer(
            BufferDescriptor(
                "vertex buffer", 
                BufferUsage.vertex, 
                vertices_size_bytes, 
                True
            )
        ))
        dst = buffer[].get_mapped_range(0, vertices_size_bytes).bitcast[MyVertex]()
        for i in range(len(vertices)):
            dst[i] = vertices[i]
        buffer[].unmap()
        return buffer        
    
