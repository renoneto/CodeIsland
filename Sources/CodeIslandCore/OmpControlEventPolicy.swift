import Foundation

public enum OmpControlEventPolicy {
    public static func shouldDrop(
        source: String?,
        normalizedEventName: String,
        hasQuestion: Bool
    ) -> Bool {
        guard SessionSnapshot.normalizedSupportedSource(source) == "omp" else {
            return false
        }
        return normalizedEventName == "PermissionRequest"
            || (normalizedEventName == "Notification" && hasQuestion)
    }
}
