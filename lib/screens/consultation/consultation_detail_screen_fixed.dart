import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../models/consultation_model.dart';
import '../../models/consultation_message_model.dart';
import '../../widgets/custom_button.dart';

class ConsultationDetailScreen extends StatefulWidget {
  final ConsultationModel consultation;

  const ConsultationDetailScreen({super.key, required this.consultation});

  @override
  State<ConsultationDetailScreen> createState() =>
      _ConsultationDetailScreenState();
}

class _ConsultationDetailScreenState extends State<ConsultationDetailScreen> {
  final _messageController = TextEditingController();
  List<ConsultationMessageModel> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  late ConsultationModel _localConsultation;

  @override
  void initState() {
    super.initState();
    _localConsultation = widget.consultation;
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final messages =
          await ApiService().getConsultationMessages(widget.consultation.id);
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading messages: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      await ApiService().sendConsultationMessage(
        widget.consultation.id,
        _messageController.text.trim(),
      );

      _messageController.clear();

      // Refresh messages
      await _loadMessages();

      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _updateConsultationStatus(String status) async {
    try {
      await ApiService().updateConsultation(
        widget.consultation.id,
        {'status': status},
      );

      // Update local consultation object
      setState(() {
        _localConsultation = _localConsultation.copyWith(
          status: status,
          acceptedAt: status == 'ACCEPTED' ? DateTime.now() : _localConsultation.acceptedAt,
          completedAt: status == 'COMPLETED' ? DateTime.now() : _localConsultation.completedAt,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consultation updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating consultation: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_localConsultation.title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Consultation details
          _buildConsultationHeader(),
          
          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildMessagesList(),
          ),
          
          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildConsultationHeader() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _localConsultation.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_localConsultation.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _localConsultation.status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _localConsultation.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.category, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  _localConsultation.category,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.priority_high, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Priority: ${_localConsultation.priority}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_localConsultation.expert != null) ...[
              const Divider(),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Expert: ${_localConsultation.expert!.username}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (_localConsultation.status == 'PENDING' &&
            _localConsultation.expert == null) ...[
          CustomButton(
            text: 'Accept',
            onPressed: () => _updateConsultationStatus('ACCEPTED'),
            backgroundColor: Colors.green,
            height: 36,
          ),
          const SizedBox(width: 8),
        ],
        if (_localConsultation.status == 'ACCEPTED' ||
            _localConsultation.status == 'IN_PROGRESS') ...[
          CustomButton(
            text: 'Mark Complete',
            onPressed: () => _updateConsultationStatus('COMPLETED'),
            backgroundColor: AppColors.primary,
            height: 36,
          ),
          const SizedBox(width: 8),
        ],
        if (_localConsultation.status == 'PENDING' &&
            _localConsultation.expert?.id == null) ...[
          CustomButton(
            text: 'Cancel',
            onPressed: () => _updateConsultationStatus('CANCELLED'),
            backgroundColor: AppColors.error,
            height: 36,
          ),
        ],
      ],
    );
  }

  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start the conversation by sending a message',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      reverse: true, // Show newest messages at the bottom
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[_messages.length - 1 - index]; // Reverse the order
        return _buildMessageItem(message);
      },
    );
  }

  Widget _buildMessageItem(ConsultationMessageModel message) {
    final isCurrentUser = message.sender.id == 1; // TODO: Get current user ID
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrentUser ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment:
              isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isCurrentUser)
              Text(
                message.sender.username,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              message.message,
              style: TextStyle(
                color: isCurrentUser ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: isCurrentUser ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
              maxLines: null,
              keyboardType: TextInputType.multiline,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: _isSending
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            onPressed: _isSending ? null : _sendMessage,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'accepted':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}