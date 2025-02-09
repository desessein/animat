struct BindGroupHelper:
    """
    Helper for creating bind group layouts and bind groups.
    Encapsulates common binding patterns.
    """
    var device: wgpu.Device

    fn __init__(inout self, device: wgpu.Device):
        self.device = device

    @staticmethod
    fn _create_bind_group(device: wgpu.Device, uniform_buffer: ArcPointer[Buffer],  layout: ArcPointer[BindGroupLayout], size: Int) -> wgpu.BindGroup:
        return device.create_bind_group(
            BindGroupDescriptor(
                "bind group",
                layout,
                List[BindGroupEntry](
                    BindGroupEntry(
                        0,
                        BufferBinding(uniform_buffer, 0, size),
                    )
                ),
            )
        )        

    @staticmethod
    fn _create_bind_group_layout(device: wgpu.Device, size: Int) -> ArcPointer[BindGroupLayout]:
        return ArcPointer(
            device.create_bind_group_layout(
                BindGroupLayoutDescriptor(
                    "bind group layout",
                    List[BindGroupLayoutEntry](
                        BindGroupLayoutEntry(
                            binding=0,
                            visibility=wgpu.ShaderStage.fragment | wgpu.ShaderStage.vertex,
                            type=BufferBindingLayout(
                                type=wgpu.BufferBindingType.uniform,
                                has_dynamic_offset=False,
                                min_binding_size=size,
                            ),
                            count=0,
                        )
                    ),
                )
            )
        )            
