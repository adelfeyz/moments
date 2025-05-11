import 'package:flutter/material.dart';

class CreateMemoryPage extends StatefulWidget {
  @override
  _CreateMemoryPageState createState() => _CreateMemoryPageState();
}

class _CreateMemoryPageState extends State<CreateMemoryPage> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  String selectedTone = 'reflective';
  bool isDraft = false;

  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _promptController = TextEditingController();

  // List of materials
  final List<MaterialItem> materials = [];

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  void _showAddMaterialModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddMaterialModal(
        onAddMaterial: (MaterialItem material) {
          setState(() {
            materials.add(material);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Memory',
          style: TextStyle(
            color: Color.fromARGB(255, 6, 154, 102),
            fontSize: 24,
          ),
        ),
        actions: [
          // Save Draft Button
          TextButton.icon(
            onPressed: () {
              setState(() {
                isDraft = true;
              });
              // TODO: Implement save draft functionality
            },
            icon: Icon(Icons.save_outlined),
            label: Text('Save Draft'),
          ),
          // Finish Button
          TextButton.icon(
            onPressed: _currentStep == 3 ? () {
              // TODO: Implement finish functionality
            } : null,
            icon: Icon(Icons.check),
            label: Text('Finish & Generate'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Custom Horizontal Stepper
          Container(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                bool isActive = _currentStep == index;
                bool isPast = _currentStep > index;
                return Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isPast || isActive
                                ? Color.fromARGB(255, 6, 154, 102)
                                : Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                          child: isPast
                              ? Icon(Icons.check, color: Colors.white, size: 16)
                              : Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: isActive ? Colors.white : Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                        ),
                        if (isActive) ...[
                          SizedBox(height: 4),
                          Text(
                            _getStepTitle(index),
                            style: TextStyle(
                              color: Color.fromARGB(255, 6, 154, 102),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (index < 3)
                      Container(
                        width: 40,
                        height: 1,
                        color: isPast
                            ? Color.fromARGB(255, 6, 154, 102)
                            : Colors.grey[300],
                      ),
                  ],
                );
              }),
            ),
          ),
          
          // Step Content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: _buildStepContent(_currentStep),
              ),
            ),
          ),
          
          // Bottom Navigation
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _currentStep--;
                      });
                    },
                    icon: Icon(Icons.arrow_back),
                    label: Text('Back'),
                  )
                else
                  SizedBox.shrink(),
                ElevatedButton(
                  onPressed: () {
                    if (_currentStep < 3) {
                      setState(() {
                        _currentStep++;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 6, 154, 102),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: Text(_currentStep == 3 ? 'Finish' : 'Continue'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(int step) {
    switch (step) {
      case 0:
        return _buildAddMaterialsStep();
      case 1:
        return _buildOrganizeContentStep();
      case 2:
        return _buildAISettingsStep();
      case 3:
        return _buildReviewAndPublishStep();
      default:
        return Container();
    }
  }

  Widget _buildAddMaterialsStep() {
    return Column(
      children: [
        // List of materials
        Container(
          height: 400,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.builder(
            itemCount: materials.length + 1, // +1 for the add button
            itemBuilder: (context, index) {
              if (index == materials.length) {
                // Add new material button
                return ListTile(
                  onTap: _showAddMaterialModal,
                  leading: CircleAvatar(
                    backgroundColor: Color.fromARGB(255, 6, 154, 102),
                    child: Icon(Icons.add, color: Colors.white),
                  ),
                  title: Text('Add New Material',
                      style: TextStyle(
                        color: Color.fromARGB(255, 6, 154, 102),
                        fontWeight: FontWeight.bold,
                      )),
                );
              }
              
              final material = materials[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color.fromARGB(255, 6, 154, 102).withOpacity(0.1),
                  child: Icon(
                    material.type.icon,
                    color: Color.fromARGB(255, 6, 154, 102),
                  ),
                ),
                title: Text(material.title),
                subtitle: Text(material.type.label),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline),
                  onPressed: () {
                    setState(() {
                      materials.removeAt(index);
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrganizeContentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Drag items to reorder your story',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 16),
        Container(
          height: 400,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: materials.isEmpty
              ? Center(
                  child: Text(
                    'Add some materials in the previous step',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                )
              : ReorderableListView.builder(
                  itemCount: materials.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) {
                        newIndex -= 1;
                      }
                      final item = materials.removeAt(oldIndex);
                      materials.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (context, index) {
                    final material = materials[index];
                    return Card(
                      key: ValueKey(material.hashCode),
                      margin: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: Container(
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, 6, 154, 102).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            material.type.icon,
                            color: Color.fromARGB(255, 6, 154, 102),
                          ),
                        ),
                        title: Text(material.title),
                        subtitle: Text(material.content.length > 50
                            ? '${material.content.substring(0, 50)}...'
                            : material.content),
                        trailing: Icon(Icons.drag_handle),
                      ),
                    );
                  },
                ),
        ),
        if (materials.isNotEmpty) ...[
          SizedBox(height: 16),
          Text(
            '👆 Drag items up or down to change their order',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAISettingsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ready to create your memory?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        TextField(
          controller: _promptController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Customize AI Prompt',
            hintText: 'Make it emotional and nostalgic...',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 16),
        Text('Choose Tone:', style: TextStyle(fontSize: 16)),
        _buildToneSelector(),
      ],
    );
  }

  Widget _buildReviewAndPublishStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Memory Preview Card
        Card(
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Memory Title
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '🗂️ That Unforgettable Sunset in Santorini',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              // Main Image
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/santorini.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              
              // Memory Paragraphs
              _buildMemoryParagraph(
                'We had just arrived in Oia, and the air smelled like salt and summer. '
                'The golden hour had just begun, casting a honeyed light over the whitewashed '
                'rooftops and cobalt-blue domes. Nina couldn\'t stop smiling—it was her dream destination.',
                128,
                7,
                hasVoice: true,
              ),
              
              _buildMediaPlaceholder(
                icon: Icons.mic,
                label: 'Voice Clip: Nina gasping at the first view of Santorini',
              ),
              
              _buildMemoryParagraph(
                'We found this quiet cliffside café, tucked behind a winding alley near Byzantine '
                'Castle Ruins. Arash ordered iced coffee, but spilled half of it laughing at one of '
                'Ramin\'s awful puns.',
                94,
                4,
              ),
              
              _buildMediaPlaceholder(
                icon: Icons.videocam,
                label: 'Video: Ramin telling a joke, everyone laughing',
              ),
              
              _buildMemoryParagraph(
                'That night, we sat on the ledge overlooking the sea. Someone started humming '
                '"Here Comes the Sun," and it just felt... right. Nina leaned her head on my shoulder. '
                'I wanted to freeze time.',
                172,
                11,
                hasAudio: true,
              ),
              
              _buildMemoryParagraph(
                'The stars slowly came out, one by one. Arash pointed out constellations. He always '
                'does that—says he\'s "anchoring the moment to the sky." We stayed there till the wind '
                'got cold and the town quieted down.',
                112,
                6,
              ),
              
              _buildMemoryParagraph(
                'The best part? We recorded it all. Voices, jokes, footsteps, laughter—and now, '
                'reading this, hearing it again… it\'s like going back.',
                135,
                8,
              ),
              
              _buildMediaPlaceholder(
                icon: Icons.videocam,
                label: 'Video: Clip of everyone saying goodbye to Santorini',
              ),
              
              // Quote
              Container(
                padding: EdgeInsets.all(16),
                alignment: Alignment.center,
                child: Text(
                  '"Some moments don\'t need filters\u2014they just need to be remembered."',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              
              // Metadata
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🕓 Created: Aug 23, 2024  ✏️ Last Edited: Sep 5, 2024'),
                    SizedBox(height: 8),
                    Text('👥 Contributors: Nina, Arash, Ramin'),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Action Buttons
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement regeneration
                },
                icon: Icon(Icons.refresh),
                label: Text('Regenerate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement save
                },
                icon: Icon(Icons.save),
                label: Text('Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 6, 154, 102),
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement share
                },
                icon: Icon(Icons.share),
                label: Text('Share'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMemoryParagraph(String text, int likes, int comments, {bool hasVoice = false, bool hasAudio = false}) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              InkWell(
                onTap: () {
                  // TODO: Implement like functionality
                },
                child: Row(
                  children: [
                    Icon(Icons.favorite_border, size: 20, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text('$likes', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
              SizedBox(width: 16),
              InkWell(
                onTap: () {
                  // TODO: Implement comment functionality
                },
                child: Row(
                  children: [
                    Icon(Icons.mic, size: 20, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text('$comments Voice Comments', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPlaceholder({required IconData icon, required String label}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToneSelector() {
    return Wrap(
      spacing: 8,
      children: [
        _buildToneChip('🎉 Fun & Light', 'fun'),
        _buildToneChip('🧘 Reflective & Calm', 'reflective'),
        _buildToneChip('🧠 Detailed & Factual', 'detailed'),
        _buildToneChip('💜 Sentimental & Heartfelt', 'sentimental'),
      ],
    );
  }

  Widget _buildToneChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: selectedTone == value,
      onSelected: (bool selected) {
        setState(() {
          selectedTone = selected ? value : selectedTone;
        });
      },
    );
  }

  String _getStepTitle(int index) {
    switch (index) {
      case 0:
        return 'Add Materials';
      case 1:
        return 'Organize Content';
      case 2:
        return 'AI Settings';
      case 3:
        return 'Review & Publish';
      default:
        return '';
    }
  }
}

// Material Type Enum
enum MaterialType {
  text(Icons.text_fields, 'Text'),
  image(Icons.image, 'Image'),
  video(Icons.videocam, 'Video'),
  voice(Icons.mic, 'Voice');

  final IconData icon;
  final String label;
  const MaterialType(this.icon, this.label);
}

// Material Item Class
class MaterialItem {
  final String title;
  final MaterialType type;
  final String content;

  MaterialItem({
    required this.title,
    required this.type,
    required this.content,
  });
}

// Add Material Modal
class AddMaterialModal extends StatefulWidget {
  final Function(MaterialItem) onAddMaterial;

  const AddMaterialModal({Key? key, required this.onAddMaterial}) : super(key: key);

  @override
  _AddMaterialModalState createState() => _AddMaterialModalState();
}

class _AddMaterialModalState extends State<AddMaterialModal> {
  final TextEditingController _textController = TextEditingController();
  final List<MaterialItem> tempMaterials = [];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _addTextMaterial() {
    if (_textController.text.isNotEmpty) {
      final material = MaterialItem(
        title: 'Text Note ${tempMaterials.length + 1}',
        type: MaterialType.text,
        content: _textController.text,
      );
      setState(() {
        tempMaterials.add(material);
        widget.onAddMaterial(material);
        _textController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Add New Material',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: tempMaterials.length,
              itemBuilder: (context, index) {
                final material = tempMaterials[index];
                return ListTile(
                  leading: Icon(material.type.icon),
                  title: Text(material.content),
                  subtitle: Text(material.type.label),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.image),
                  onPressed: () {
                    // TODO: Implement image picker
                  },
                ),
                IconButton(
                  icon: Icon(Icons.videocam),
                  onPressed: () {
                    // TODO: Implement video picker
                  },
                ),
                IconButton(
                  icon: Icon(Icons.mic),
                  onPressed: () {
                    // TODO: Implement voice recorder
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Type your text here...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _addTextMaterial,
                  color: Color.fromARGB(255, 6, 154, 102),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 