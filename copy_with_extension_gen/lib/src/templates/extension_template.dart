import 'package:copy_with_extension_gen/src/resolved_copy_with_spec.dart';

import 'copy_with_null_template.dart';
import 'proxy_template.dart';

/// Builds the entire extension code snippet.
/// This method assembles the proxy class and the extension declaration that is added to the generated file.
String extensionTemplate(ResolvedCopyWithSpec spec) {
  final proxy = copyWithProxyTemplate(spec);
  final copyWithNullBlock =
      spec.generatesCopyWithNull ? copyWithNullTemplate(spec) : '';
  final trackChangesBlock =
      spec.generatesTrackChanges ? _trackChangesTemplate(spec) : '';

  return '''
    $proxy

    $trackChangesBlock

    extension ${spec.extensionName} on ${spec.typeAnnotation} {
      /// Returns a callable class used to build a new instance with modified fields.
      /// Example: `instanceOf${spec.className}.copyWith(...)`${spec.skipFields ? "" : " or `instanceOf${spec.className}.copyWith.fieldName(...)`"}.
      // ignore: library_private_types_in_public_api
      ${spec.proxyInterfaceRef} get copyWith => ${spec.proxyImplRef}(this);

      $copyWithNullBlock
    }
    ''';
}

String _trackChangesTemplate(ResolvedCopyWithSpec spec) {
  final getChangesMethod = spec.uniqueFields
      .map(
        (field) =>
            "    if (_changedFields.contains('${field.name}')) '${field.name}': (this as dynamic).${field.name},",
      )
      .join('\n');

  return '''
    /// Global storage for tracking changed fields per instance.
    final ${spec.changedFieldsStorageName} = Expando<Set<String>>();

    /// Mixin that exposes changed field tracking for ${spec.className}.
    mixin ${spec.trackChangesMixinName} {
      Set<String> get _changedFields => ${spec.changedFieldsStorageName}[this] ??= <String>{};

      Set<String> get changedFields => Set.unmodifiable(_changedFields);

      bool get hasChanges => _changedFields.isNotEmpty;

      Map<String, dynamic> getChanges() => {
$getChangesMethod
      };
    }
    ''';
}
