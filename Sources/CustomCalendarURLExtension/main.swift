// Never runs: the linker sets the entry point to Foundation's NSExtensionMain,
// which looks up ConferenceProvider from the Info.plist. SwiftPM still wants
// an executable target to have a main file.
