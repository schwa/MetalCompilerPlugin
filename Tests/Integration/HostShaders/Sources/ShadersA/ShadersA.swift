public enum ShadersA {
    #if METAL_COMPILER_PLUGIN_DEBUG
    public static let swiftSeesDebugDefine = true
    #else
    public static let swiftSeesDebugDefine = false
    #endif
}
