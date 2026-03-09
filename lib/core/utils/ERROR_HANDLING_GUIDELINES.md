# Error Handling Guidelines

This document outlines the standardized error handling approach used in the Mlimi Flutter application.

## Overview

The application uses a centralized error handling system with the following components:

1. **ErrorHandler Utility** - Centralized error handling and user feedback
2. **Service Result Wrappers** - Standardized response format from services
3. **API Exception Classes** - Specific exception types for different error scenarios
4. **UI Feedback Patterns** - Consistent user feedback mechanisms

## ErrorHandler Utility

The `ErrorHandler` class provides standardized methods for displaying feedback to users:

### Methods

```dart
// Show error snackbar
ErrorHandler.showErrorSnackBar(BuildContext context, String message);

// Show success snackbar
ErrorHandler.showSuccessSnackBar(BuildContext context, String message);

// Show info snackbar
ErrorHandler.showInfoSnackBar(BuildContext context, String message);

// Show warning snackbar
ErrorHandler.showWarningSnackBar(BuildContext context, String message);

// Show error dialog
ErrorHandler.showErrorDialog(BuildContext context, String title, String message);

// Show confirmation dialog
ErrorHandler.showConfirmationDialog(BuildContext context, String title, String message);

// Format API error messages
ErrorHandler.formatApiErrorMessage(dynamic error);

// Handle common exception types
ErrorHandler.handleException(Object exception);
```

## Service Result Wrappers

All service methods return standardized result objects:

### CommunityResult
```dart
class CommunityResult {
  final bool isSuccess;
  final String message;
  final List<CommunityPostModel> posts;
  final List<CommunityReplyModel> replies;
  final int totalCount;
  final bool hasNext;
  final bool hasPrevious;
  final Map<String, dynamic>? extraData;
}
```

### AuthResult
```dart
class AuthResult {
  final bool isSuccess;
  final String message;
  final UserModel? user;
  final Map<String, dynamic>? errors;
  final dynamic data;
}
```

### ServiceResult<T>
```dart
class ServiceResult<T> {
  final bool isSuccess;
  final String message;
  final T? data;
  final Map<String, dynamic>? errors;
  final dynamic extraData;
}
```

### DiagnosisServiceResult
```dart
class DiagnosisServiceResult {
  final bool isSuccess;
  final String message;
  final DiagnosisResult? result;
  final List<PestDiagnosisModel> diagnoses;
  final int totalCount;
  final bool hasNext;
  final bool hasPrevious;
  final Map<String, dynamic>? extraData;
}
```

## API Exception Classes

The application defines specific exception types:

- `ApiException` - Base API exception
- `NetworkException` - Network connectivity issues
- `TimeoutException` - Request timeout
- `UnauthorizedException` - Authentication required
- `ForbiddenException` - Insufficient permissions
- `NotFoundException` - Resource not found
- `BadRequestException` - Invalid request
- `ValidationException` - Validation errors
- `ServerException` - Server errors
- `RequestCancelledException` - Cancelled requests

## Implementation Patterns

### Service Layer
```dart
Future<CommunityResult> createPost(CommunityPostCreateRequest request) async {
  try {
    final response = await _apiService.post(
      AppConstants.communityPosts,
      data: request.toJson(),
    );

    if (response.statusCode == 201) {
      final post = CommunityPostModel.fromJson(response.data);
      return CommunityResult.success(
        posts: [post],
        message: 'Post created successfully',
      );
    }

    return CommunityResult.failure(ErrorHandler.formatApiErrorMessage(response.data));
  } on ValidationException catch (e) {
    return CommunityResult.failure('Validation error: ${ErrorHandler.formatApiErrorMessage(e.message)}');
  } on ApiException catch (e) {
    return CommunityResult.failure('Failed to create post: ${ErrorHandler.formatApiErrorMessage(e.message)}');
  } catch (e) {
    return CommunityResult.failure(ErrorHandler.handleException(e));
  }
}
```

### UI Layer
```dart
Future<void> _submitPost() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() {
    _isLoading = true;
  });

  try {
    final request = CommunityPostCreateRequest(
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      category: _selectedCategory,
      isQuestion: _isQuestion,
    );

    final result = await _communityService.createPost(request);

    if (result.isSuccess) {
      ErrorHandler.showSuccessSnackBar(context, 'Post created successfully!');
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } else {
      ErrorHandler.showErrorSnackBar(context, result.message);
    }
  } catch (e) {
    ErrorHandler.showErrorSnackBar(context, ErrorHandler.handleException(e));
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
```

## Best Practices

1. **Always use try-catch blocks** in async methods
2. **Check mounted state** before updating UI
3. **Use specific exception handling** when possible
4. **Provide meaningful error messages** to users
5. **Log errors appropriately** for debugging
6. **Handle network errors gracefully**
7. **Provide offline functionality** where possible
8. **Use consistent feedback patterns** throughout the app

## Error Message Guidelines

1. **Be clear and concise**
2. **Avoid technical jargon**
3. **Provide actionable information**
4. **Be empathetic**
5. **Include recovery suggestions** when possible

### Examples

**Good:**
- "Please check your internet connection and try again"
- "Your session has expired. Please log in again"
- "The requested resource was not found"

**Avoid:**
- "Error 500 occurred"
- "Something went wrong"
- "An unexpected error happened"

## Testing Error Handling

1. **Test network error scenarios**
2. **Test timeout conditions**
3. **Test authentication failures**
4. **Test validation errors**
5. **Test server errors**
6. **Test edge cases**

## Future Improvements

1. **Add retry mechanisms** for transient errors
2. **Implement offline caching** with sync capabilities
3. **Add error reporting** to analytics services
4. **Implement progressive error handling** with multiple recovery options
5. **Add accessibility features** for error messages