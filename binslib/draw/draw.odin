package draw

import "gl33"

init :: proc() {
	gl33.init()
}

deinit :: proc() {
	gl33.deinit()
}

begin_frame :: proc() {
	gl33.begin_frame()
}

end_frame :: proc() {
	gl33.end_frame()
}
