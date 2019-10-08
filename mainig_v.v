// V standalone example application for dear imgui + SDL2 + OpenGL
module main
import vsdl2
import vig
fn main() {
	C.SDL_Init(C.SDL_INIT_VIDEO | C.SDL_INIT_AUDIO)
	glsl_version := "#version 130"
	C.SDL_GL_SetAttribute(C.SDL_GL_DOUBLEBUFFER, 1)
	C.SDL_GL_SetAttribute(C.SDL_GL_DEPTH_SIZE, 24)
	C.SDL_GL_SetAttribute(C.SDL_GL_STENCIL_SIZE, 8)
	window_flags := C.SDL_WINDOW_OPENGL | C.SDL_WINDOW_RESIZABLE | C.SDL_WINDOW_ALLOW_HIGHDPI
	window := C.SDL_CreateWindow("V ImGui+SDL2+OpenGL3 example", C.SDL_WINDOWPOS_CENTERED, C.SDL_WINDOWPOS_CENTERED, 800, 600, window_flags)
	gl_context := C.SDL_GL_CreateContext(window)
	C.SDL_GL_MakeCurrent(window, gl_context)
	C.SDL_GL_SetSwapInterval(1) // Enable vsync
	C.glewInit()
	C.igCreateContext(C.NULL)
	io := C.igGetIO()
	C.igStyleColorsDark(C.NULL)
	C.ImGui_ImplSDL2_InitForOpenGL(window, gl_context)
	C.ImGui_ImplOpenGL3_Init(glsl_version.str)
	// Our state
	show_demo_window := true
	mut show_another_window := false
	clear_color := ImVecFour{0.45, 0.55, 0.60, 1.00}
	size0 := ImVecTwo {0, 0}
	f := 0.0
	mut counter := 0
	mut done := false
	for !done {
		ev := SdlEvent{}
		for 0 < C.SDL_PollEvent(&ev) {
			C.ImGui_ImplSDL2_ProcessEvent(&ev)
			switch int(ev._type) {
				case C.SDL_QUIT:
					done = true
					break
			}
		}
		// Start the Dear ImGui frame
		C.ImGui_ImplOpenGL3_NewFrame()
		C.ImGui_ImplSDL2_NewFrame(window)
		C.igNewFrame()
		// 1. Show the big demo window
		if show_demo_window {
			C.igShowDemoWindow(&show_demo_window)
		}
		// 2. Show a simple window that we create ourselves. We use a Begin/End pair to created a named window.
		{
		C.igBegin("Hello, Vorld!", C.NULL, 0)        // Create a window called "Hello, world!" and append into it.
		C.igText("This is some useful text.")               // Display some text (you can use a format strings too)
		C.igCheckbox("Demo Vindow", &show_demo_window)      // Edit bools storing our window open/close state
		C.igCheckbox("Another Vindow", &show_another_window)
		C.igSliderFloat("float", &f, 0.0, 1.0, 0, 0)            // Edit 1 float using a slider from 0.0f to 1.0f
		C.igColorEdit3("clear color", &clear_color, 0) // Edit 3 floats representing a color
		if C.igButton("Button", size0) {                            // Buttons return true when clicked (most widgets return true when edited/activated)
			counter++
		}
		C.igSameLine(0, 0)
		C.igText("counter = %d", counter)
//		C.igText("Application average %.3f ms/frame (%.1f FPS)", 1000.0 / io->Framerate, io->Framerate)
		C.igEnd()
		}
		// 3. Show another simple window.
		if (show_another_window) {
			C.igBegin("Another Vindow", &show_another_window, 0)   // Pass a pointer to our bool variable (the window will have a closing button that will clear the bool when clicked)
			C.igText("Hello from another Vindow!")
			if C.igButton("Close Me", size0) {
				show_another_window = false
			}
			C.igEnd()
		}
		// Rendering
		C.igRender()
//		C.glViewport(0, 0, int(io->DisplaySize.x), int(io->DisplaySize.y))
		C.glClearColor(clear_color.x, clear_color.y, clear_color.z, clear_color.w)
		C.glClear(C.GL_COLOR_BUFFER_BIT)
		C.ImGui_ImplOpenGL3_RenderDrawData(C.igGetDrawData())
		C.SDL_GL_SwapWindow(window)
	}
	// Cleanup => TODO
}
