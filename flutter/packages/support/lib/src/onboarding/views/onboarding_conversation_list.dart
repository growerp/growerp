/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 *
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 *
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_chat/growerp_chat.dart';

class OnboardingConversationList extends StatefulWidget {
  const OnboardingConversationList({super.key});

  @override
  State<OnboardingConversationList> createState() =>
      _OnboardingConversationListState();
}

class _OnboardingConversationListState
    extends State<OnboardingConversationList> {
  final _scrollController = ScrollController();
  static const _scrollThreshold = 200.0;
  late ChatRoomBloc _chatRoomBloc;
  List<ChatRoom> _chatRooms = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _chatRoomBloc = context.read<ChatRoomBloc>()
      ..add(const ChatRoomFetch(
        refresh: true,
        namePrefix: 'Onboarding:',
      ));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll > 0 && maxScroll - currentScroll <= _scrollThreshold) {
      _chatRoomBloc.add(const ChatRoomFetch(namePrefix: 'Onboarding:'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatRoomBloc, ChatRoomState>(
      listener: (context, state) {
        if (state.status == ChatRoomStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
      },
      builder: (context, state) {
        if (state.status == ChatRoomStatus.failure) {
          return FatalErrorForm(
            message: 'Error loading onboarding conversations: ${state.message}',
          );
        }
        if (state.status == ChatRoomStatus.initial) {
          return const Center(child: LoadingIndicator());
        }
        _chatRooms = state.chatRooms;
        return Scaffold(
          appBar: AppBar(title: const Text('Onboarding Conversations')),
          body: _chatRooms.isEmpty
              ? const Center(
                  child: Text(
                    'No onboarding conversations found.',
                    key: Key('empty'),
                  ),
                )
              : ListView.builder(
                  key: const Key('listView'),
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: state.hasReachedMax
                      ? _chatRooms.length
                      : _chatRooms.length + 1,
                  itemBuilder: (context, index) {
                    if (index >= _chatRooms.length) {
                      return const BottomLoader();
                    }
                    final room = _chatRooms[index];
                    // Room name format: "Onboarding: {company} [{appId}] {date}"
                    final raw = room.chatRoomName ?? '';
                    final inner =
                        raw.startsWith('Onboarding: ')
                            ? raw.substring('Onboarding: '.length)
                            : raw;
                    final bracketIdx = inner.lastIndexOf(' [');
                    final company = bracketIdx > 0
                        ? inner.substring(0, bracketIdx)
                        : inner;
                    final rest = bracketIdx > 0
                        ? inner.substring(bracketIdx + 2).replaceAll(']', '')
                        : '';
                    final parts = rest.split(' ');
                    final appId = parts.isNotEmpty ? parts[0] : '';
                    final date = parts.length > 1 ? parts[1] : '';
                    return ListTile(
                      key: Key('onboardingRoom$index'),
                      leading: CircleAvatar(
                        child: Text(
                          company.isNotEmpty ? company[0].toUpperCase() : '?',
                        ),
                      ),
                      title: Text(
                        company.isNotEmpty ? company : '(unnamed)',
                        key: Key('roomName$index'),
                      ),
                      subtitle: Text('$appId  $date'.trim()),
                      onTap: () async {
                        await showDialog(
                          context: context,
                          barrierDismissible: true,
                          builder: (_) => ChatDialog(room),
                        );
                        if (context.mounted) {
                          _chatRoomBloc.add(const ChatRoomFetch(
                            refresh: true,
                            namePrefix: 'Onboarding:',
                          ));
                        }
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}
