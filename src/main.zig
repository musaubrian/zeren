const std = @import("std");
const Zeren = @import("Zeren.zig");
const Zerui = @import("Zerui.zig");
const examples = @import("examples.zig");
const Zpm = @import("Zpm.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try Zeren.init();
    defer Zeren.deinit();

    var window = try Zeren.Window.createWindow(800, 600, "Zeren", .{ .bg_color = null, .fullscreen = true });
    defer window.destroy();

    var tringle = try examples.Triangle.init(allocator, .None);
    defer tringle.deinit();
    var rect = try examples.Rectangle.init(allocator, .None);
    defer rect.deinit();

    var cc_tringle = try examples.PulsingTriangle.init(allocator, .Fill);
    defer cc_tringle.deinit();

    var rb_tringle = try examples.RainbowTriangle.init(allocator, .Fill);
    defer rb_tringle.deinit();

    var ppm = Zpm.init(allocator);
    try ppm.loadAndParse("./assets/sample_640×426.ppm");
    try ppm.renderText();

    while (!window.shouldClose()) {
        if (window.closeWindowEvt()) break;
        window.beginFrame();
        try tringle.draw();
        try cc_tringle.draw();
        try rb_tringle.draw();
        try rect.draw();
        window.endFrame();
    }
}
