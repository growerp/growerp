import 'package:flutter/material.dart';

/// Step 1: Lead Capture Screen
/// Collects respondent information: name, email, company
class LeadCaptureScreen extends StatefulWidget {
  final String assessmentId;
  final Function({
    required String name,
    required String email,
    required String company,
    required String phone,
  }) onRespondentDataCollected;
  final VoidCallback onNext;

  const LeadCaptureScreen({
    Key? key,
    required this.assessmentId,
    required this.onRespondentDataCollected,
    required this.onNext,
  }) : super(key: key);

  @override
  State<LeadCaptureScreen> createState() => _LeadCaptureScreenState();
}

class _LeadCaptureScreenState extends State<LeadCaptureScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _companyController;
  late TextEditingController _phoneController;

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _companyController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Store respondent data
      widget.onRespondentDataCollected(
        name: _nameController.text,
        email: _emailController.text,
        company: _companyController.text,
        phone: _phoneController.text,
      );

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() => _isLoading = false);
          widget.onNext();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assessment - Step 1: Your Information'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          child: Column(
            children: [
              // Progress indicator
              _buildProgressIndicator(),
              SizedBox(height: isMobile ? 24 : 40),

              // Form
              _buildForm(context),
              SizedBox(height: isMobile ? 24 : 40),

              // Navigation buttons
              _buildNavigationButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      // Compact mobile layout
      return Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCompactStepIndicator(1, true),
                const Flexible(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.chevron_right, size: 16),
                  ),
                ),
                _buildCompactStepIndicator(2, false),
                const Flexible(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.chevron_right, size: 16),
                  ),
                ),
                _buildCompactStepIndicator(3, false),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Step 1 of 3',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      );
    }

    // Desktop layout
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStepIndicator(1, true, 'Your\nInfo'),
            Expanded(
              child: Container(
                height: 2,
                color: Colors.grey[300],
                margin: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
            _buildStepIndicator(2, false, 'Quest-\nions'),
            Expanded(
              child: Container(
                height: 2,
                color: Colors.grey[300],
                margin: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
            _buildStepIndicator(3, false, 'Results'),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Step 1 of 3',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildCompactStepIndicator(int step, bool isActive) {
    return Flexible(
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? Colors.blue : Colors.grey[300],
        ),
        child: Center(
          child: Text(
            step.toString(),
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey[600],
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, bool isActive, String label) {
    return SizedBox(
      width: 50,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.blue : Colors.grey[300],
            ),
            child: Center(
              child: Text(
                step.toString(),
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isActive ? Colors.blue : Colors.grey[600],
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Let\'s start with your information',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Please provide your details to begin the assessment',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 32),

          // Name field
          _buildTextField(
            key: const Key('respondentName'),
            controller: _nameController,
            label: 'Full Name *',
            hint: 'Enter your full name',
            icon: Icons.person,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Name is required';
              }
              if ((value?.length ?? 0) < 2) {
                return 'Name must be at least 2 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Email field
          _buildTextField(
            key: const Key('respondentEmail'),
            controller: _emailController,
            label: 'Email Address *',
            hint: 'Enter your email address',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Email is required';
              }
              if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                  .hasMatch(value!)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Company field (optional)
          _buildTextField(
            key: const Key('respondentCompany'),
            controller: _companyController,
            label: 'Company Name',
            hint: 'Enter your company name (optional)',
            icon: Icons.business,
          ),
          const SizedBox(height: 16),

          // Phone field (optional)
          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: 'Enter your phone number (optional)',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    Key? key,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: key,
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(BuildContext context) {
    return Wrap(
      spacing: 12,
      alignment: WrapAlignment.spaceEvenly,
      children: [
        OutlinedButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          key: const Key('nextToAssessment'),
          onPressed: _isLoading ? null : _handleNext,
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Next'),
        ),
      ],
    );
  }
}
