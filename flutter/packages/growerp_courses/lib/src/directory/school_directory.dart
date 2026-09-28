/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_courses/l10n/generated/courses_localizations.dart';
import 'package:growerp_models/growerp_models.dart';

/// Public list of the schools (companies with a published course) a learner
/// can join. Shown by the academy app when it was not started for a school.
class SchoolDirectory extends StatefulWidget {
  const SchoolDirectory({super.key, required this.onSelected});

  final ValueChanged<Company> onSelected;

  @override
  State<SchoolDirectory> createState() => _SchoolDirectoryState();
}

class _SchoolDirectoryState extends State<SchoolDirectory> {
  final _searchController = TextEditingController();
  List<Company> _schools = [];
  bool _loading = true;
  bool _failed = false;
  // enterText fires onChanged twice: only the latest search may set the list
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _load('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load(String searchString) async {
    final requestId = ++_requestId;
    setState(() => _loading = true);
    try {
      final result = await context.read<RestClient>().getAcademyDirectory(
        searchString: searchString.isEmpty ? null : searchString,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _schools = result.companies;
        _loading = false;
        _failed = false;
      });
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = CoursesLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(localizations.courses_chooseSchool)),
      body: Column(
        children: [
          ListFilterBar(
            searchHint: localizations.courses_searchHintSchools,
            searchController: _searchController,
            onSearchChanged: _load,
          ),
          Expanded(
            child: _failed
                ? FatalErrorForm(
                    message: localizations.courses_couldNotLoadSchools,
                  )
                : StyledDataTable(
                    columns: [
                      const StyledColumn(header: '', flex: 1),
                      StyledColumn(
                        header: localizations.courses_tableHdrSchool,
                        flex: 5,
                      ),
                    ],
                    rows: [
                      for (final (index, school) in _schools.indexed)
                        [
                          CircleAvatar(
                            key: Key('schoolLogo$index'),
                            backgroundImage: school.image != null
                                ? MemoryImage(school.image!)
                                : null,
                            child: school.image == null
                                ? const Icon(Icons.school)
                                : null,
                          ),
                          Text(
                            school.name ?? '',
                            key: Key('schoolName$index'),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                    ],
                    isLoading: _loading && _schools.isEmpty,
                    onRowTap: (index) => widget.onSelected(_schools[index]),
                  ),
          ),
        ],
      ),
    );
  }
}
