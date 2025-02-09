@value
struct Vec3:
    var x: Float32
    var y: Float32
    var z: Float32


@value
struct MyColor:
    var r: Float32
    var g: Float32
    var b: Float32
    var a: Float32


@value
struct MyVertex:
    var pos: Vec3
    var color: MyColor
