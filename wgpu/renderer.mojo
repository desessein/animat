from wgpu import *
from .types import *
from sys.info import sizeof
from .objects import RenderPassEncoder

struct Renderer[T: Animation]:
    var device: wgpu.Device
    var pipeline: wgpu.RenderPipeline
    var surface: wgpu.Surface
    var vertex_buffer: ArcPointer[wgpu.Buffer]
    var uniform_bind_group: wgpu.BindGroup
    var uniform_buffer: ArcPointer[wgpu.Buffer]
    var queue: wgpu.Queue
    var adapter: wgpu.Adapter
    var animation: T

    fn __init__(mut self, ref window: glfw.Window, animation: T) raises:
        self.animation = animation
        instance = wgpu.Instance()
        self.surface = instance.create_surface(window)
        self.adapter = instance.request_adapter_sync(self.surface)
        self.device = self.adapter.adapter_request_device()
        self.queue = self.device.get_queue()
        
        # Configure surface
        caps = self.surface.get_capabilities(self.adapter)
        surface_formats = caps.formats()
        format_0 = surface_formats[0]
        # Copy the first format value before caps is destroyed

        self.surface.configure(
            self.device,
            SurfaceConfiguration(
                width=640, height=480,
                usage=wgpu.TextureUsage.render_attachment,
                format=format_0,
                alpha_mode=wgpu.CompositeAlphaMode.auto,
                present_mode=wgpu.PresentMode.fifo,
                view_formats=List[TextureFormat](),
            )
        )        

        # Create shader and pipeline
        shader_module = animation.create_shader_module(self.device)
        bind_group_layout = animation.create_bind_group_layout(self.device)
        pipeline_layout = self.create_pipeline_layout(self.device, bind_group_layout)
        self.pipeline = self._create_pipeline(self.device, shader_module, pipeline_layout, format_0, animation.create_vertex_attributes())

        # Create buffers and bind groups
        self.uniform_buffer = animation.create_uniform_buffer(self.device)
        self.uniform_bind_group = animation.create_bind_group(self.device, self.uniform_buffer, bind_group_layout)
        self.vertex_buffer = animation.create_vertex_buffer(self.device) 

    
    @staticmethod
    fn create_pipeline_layout(
        device: wgpu.Device,
        bind_group_layout: ArcPointer[BindGroupLayout],
    ) -> PipelineLayout:
        return device.create_pipeline_layout(
            PipelineLayoutDescriptor(
                "pipeline layout",
                List[ArcPointer[BindGroupLayout]](bind_group_layout),
            )
        )

    @staticmethod
    fn _create_pipeline(
        device: wgpu.Device, 
        shader_module: wgpu.ShaderModule, 
        pipeline_layout: PipelineLayout,
        surface_format: TextureFormat,
        vertex_attributes: List[VertexAttribute]
    ) -> wgpu.RenderPipeline:
        vertex_buffer_layout = VertexBufferLayout(
            array_stride=sizeof[MyVertex](),
            step_mode=VertexStepMode.vertex,
            attributes=Span(vertex_attributes),
        )

        desc = wgpu.RenderPipelineDescriptor(
            label="render pipeline",
            vertex=wgpu.VertexState(
                entry_point="vs_main",
                module=shader_module,
                buffers=List[VertexBufferLayout[__origin_of(vertex_attributes)]](
                    vertex_buffer_layout
                ),
            ),
            fragment=wgpu.FragmentState(
                module=shader_module,
                entry_point="fs_main",
                targets=List[wgpu.ColorTargetState](
                    wgpu.ColorTargetState(
                        blend=wgpu.BlendState(
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
                        ),
                        format=surface_format,
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
        return device.create_render_pipeline(descriptor=desc)

    fn render(self, ref u_time: Float32) raises -> Float32:
        with self.surface.get_current_texture() as surface_tex:
            if surface_tex.status != wgpu.SurfaceGetCurrentTextureStatus.success:
                raise Error("failed to get surface tex")
            
            target_view = surface_tex.texture[].create_view(
                format=surface_tex.texture[].get_format(),
                dimension=wgpu.TextureViewDimension.d2,
                base_mip_level=0,
                mip_level_count=1,
                base_array_layer=0,
                array_layer_count=1,
                aspect=wgpu.TextureAspect.all,
            )

            encoder = self.device.create_command_encoder()
            
            color_attachments = List[wgpu.RenderPassColorAttachment](
                wgpu.RenderPassColorAttachment(
                    view=target_view,
                    load_op=wgpu.LoadOp.clear,
                    store_op=wgpu.StoreOp.store,
                    clear_value=wgpu.Color(0.9, 0.1, 0.2, 1.0),
                )
            )

            self.queue.write_buffer(
                self.uniform_buffer,
                0,
                Span[UInt8, __origin_of(u_time)](
                    ptr=UnsafePointer.address_of(u_time).bitcast[UInt8](),
                    length=sizeof[Float32](),
                ),
            )

            rp = encoder.begin_render_pass(color_attachments=color_attachments)
            rp.set_pipeline(self.pipeline)
            rp.set_vertex_buffer(0, 0, self.vertex_buffer[].get_size(), self.vertex_buffer[])
            rp.set_bind_group(0, self.uniform_bind_group, List[UInt32]())
            rp.draw(self.animation.get_total_vertices(), 1, 0, 0)
            rp.end()

            command = encoder.finish()
            self.queue.submit(command)
            self.surface.present()
            
            return u_time + 0.05
            
