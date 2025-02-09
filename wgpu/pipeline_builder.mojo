from .wgpu import *

struct PipelineBuilder:
    """
    A generic builder for creating WebGPU pipelines.
    This encapsulates the common pipeline creation logic.
    """
    var device: wgpu.Device
    var surface_format: TextureFormat

    fn __init__(mut self, device: wgpu.Device, surface_format: TextureFormat):
        self.device = device
        self.surface_format = surface_format

    fn create_shader_pipeline(
        self,
        shader_code: String,
        vertex_layout: VertexBufferLayout,
        bind_group_layouts: List[ArcPointer[BindGroupLayout]],
    ) raises -> wgpu.RenderPipeline:
        vertex_attributes = List[VertexAttribute](
            VertexAttribute(
                format=VertexFormat.float32x3, 
                offset=0, 
                shader_location=0
            ),
            VertexAttribute(
                format=VertexFormat.float32x4,
                offset=sizeof[Vec3](),
                shader_location=1,
            ),
        )

        vertex_buffer_layout = VertexBufferLayout(
            array_stride=sizeof[MyVertex](),
            step_mode=VertexStepMode.vertex,
            attributes=Span(vertex_attributes),
        )

        # Create shader module (generic)
        shader = self.device.create_wgsl_shader_module(code=shader_code)

        # Create pipeline layout (generic)
        pipeline_layout = self.device.create_pipeline_layout(
            PipelineLayoutDescriptor(
                "pipeline layout",
                bind_group_layouts,
            )
        )

        # Create complete pipeline with standard settings
        return self.device.create_render_pipeline(
            wgpu.RenderPipelineDescriptor(
                label="render pipeline",
                vertex=wgpu.VertexState(
                    entry_point="vs_main",
                    module=shader,
                    buffers=List[VertexBufferLayout[__origin_of(vertex_attributes)]](vertex_buffer_layout),
                ),
                fragment=wgpu.FragmentState(
                    module=shader,
                    entry_point="fs_main",
                    targets=List[wgpu.ColorTargetState](
                        wgpu.ColorTargetState(
                            blend=self._create_default_blend_state(),
                            format=self.surface_format,
                            write_mask=wgpu.ColorWriteMask.all,
                        )
                    ),
                ),
                primitive=wgpu.PrimitiveState(
                    topology=wgpu.PrimitiveTopology.triangle_list,
                ),
                multisample=wgpu.MultisampleState(),
                layout=Pointer.address_of(pipeline_layout),
                depth_stencil=None,
            )
        )

    fn _create_default_blend_state(self) -> wgpu.BlendState:
        """Creates a standard alpha blending state."""
        return wgpu.BlendState(
            color=wgpu.BlendComponent(
                src_factor=wgpu.BlendFactor.src_alpha,
                dst_factor=wgpu.BlendFactor.one_minus_src_alpha,
                operation=wgpu.BlendOperation.add,
            ),
            alpha=wgpu.BlendComponent(
                src_factor=wgpu.BlendFactor.zero,
                dst_factor=wgpu.BlendFactor.one,
                operation=wgpu.BlendOperation.add,
            ),
        )