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
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

class PersonaTest {
  static Future<void> selectPersonas(WidgetTester tester) async {
    await CommonTest.selectOption(
      tester,
      '/personas',
      'PersonaList',
      null,
    );
  }

  static Future<void> addPersonas(
    WidgetTester tester,
    List<Persona> personas,
  ) async {
    SaveTest test = await PersistFunctions.getTest();
    await PersistFunctions.persistTest(test.copyWith(personas: personas));
    await enterPersonaData(tester);
  }

  static Future<void> updatePersonas(
    WidgetTester tester,
    List<Persona> newPersonas,
  ) async {
    SaveTest old = await PersistFunctions.getTest();
    // copy IDs to new data
    List<Persona> updatedPersonas = [];
    for (int x = 0; x < newPersonas.length; x++) {
      updatedPersonas.add(
        newPersonas[x].copyWith(
          personaId: old.personas[x].personaId,
          pseudoId: old.personas[x].pseudoId,
        ),
      );
    }
    await PersistFunctions.persistTest(old.copyWith(personas: updatedPersonas));
    await enterPersonaData(tester);
  }

  static Future<void> deletePersonas(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    int count = test.personas.length;
    expect(
      find.byKey(const Key('personaItem'), skipOffstage: false),
      findsNWidgets(count),
    );
    await CommonTest.tapByKey(
      tester,
      'delete0',
      seconds: CommonTest.waitTime,
    );
    await CommonTest.tapByKey(
      tester,
      'deleteConfirm0',
      seconds: CommonTest.waitTime,
    );
    expect(
      find.byKey(const Key('personaItem'), skipOffstage: false),
      findsNWidgets(count - 1),
    );
    await PersistFunctions.persistTest(
      test.copyWith(personas: test.personas.sublist(1, count)),
    );
  }

  /// Search for personas using ListFilterBar and tap the first result
  static Future<void> doPersonaSearch(
    WidgetTester tester, {
    required String searchString,
  }) async {
    await CommonTest.enterText(tester, 'searchField', searchString);
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
    await CommonTest.tapByKey(tester, 'name0');
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
  }

  /// Clear the search field to show all items
  static Future<void> clearSearch(WidgetTester tester) async {
    await CommonTest.enterText(tester, 'searchField', '');
    await tester.pumpAndSettle(const Duration(seconds: CommonTest.waitTime));
  }

  static Future<void> enterPersonaData(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    List<Persona> newPersonas = [];

    for (Persona persona in test.personas) {
      if (persona.pseudoId == null) {
        // Add new persona
        await CommonTest.tapByKey(tester, 'addNewPersona');
      } else {
        // Update existing persona - use custom search
        await doPersonaSearch(tester, searchString: persona.pseudoId!);
        expect(
          CommonTest.getTextField('topHeader').contains(persona.pseudoId!),
          true,
        );
      }

      // Check for the detail screen (key varies based on pseudoId)
      final expectedKey = persona.pseudoId == null
          ? 'PersonaDetailnull'
          : 'PersonaDetail${persona.pseudoId}';
      expect(find.byKey(Key(expectedKey)), findsOneWidget);

      // Enter persona info
      await CommonTest.enterText(tester, 'name', persona.name);

      if (persona.demographics != null) {
        await CommonTest.enterText(
            tester, 'demographics', persona.demographics!);
      }

      if (persona.painPoints != null) {
        await CommonTest.dragUntil(
          tester,
          key: 'painPoints',
          listViewName: 'personaDetailListView',
        );
        await CommonTest.enterText(tester, 'painPoints', persona.painPoints!);
      }

      if (persona.goals != null) {
        await CommonTest.dragUntil(
          tester,
          key: 'goals',
          listViewName: 'personaDetailListView',
        );
        await CommonTest.enterText(tester, 'goals', persona.goals!);
      }

      if (persona.toneOfVoice != null) {
        await CommonTest.dragUntil(
          tester,
          key: 'toneOfVoice',
          listViewName: 'personaDetailListView',
        );
        await CommonTest.enterText(tester, 'toneOfVoice', persona.toneOfVoice!);
      }

      // Save the persona
      await CommonTest.dragUntil(
        tester,
        key: 'personaDetailSave',
        listViewName: 'personaDetailListView',
      );
      await CommonTest.tapByKey(
        tester,
        'personaDetailSave',
        seconds: CommonTest.waitTime,
      );

      // Get allocated ID for new personas
      if (persona.pseudoId == null) {
        await CommonTest.tapByKey(tester, 'name0',
            seconds: CommonTest.waitTime);
        var id = CommonTest.getTextField('topHeader').split('#')[1].trim();
        persona = persona.copyWith(pseudoId: id);
        await CommonTest.tapByKey(tester, 'cancel');
      }

      newPersonas.add(persona);
    }

    await clearSearch(tester);
    await PersistFunctions.persistTest(test.copyWith(personas: newPersonas));
  }

  static Future<void> checkPersonas(WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest(backup: false);

    for (Persona persona in test.personas) {
      await doPersonaSearch(tester, searchString: persona.pseudoId!);

      // Check detail - the dialog key is PersonaDetail${pseudoId}
      expect(
          find.byKey(Key('PersonaDetail${persona.pseudoId}')), findsOneWidget);
      expect(CommonTest.getTextFormField('name'), equals(persona.name));

      if (persona.demographics != null) {
        expect(
          CommonTest.getTextFormField('demographics'),
          equals(persona.demographics!),
        );
      }

      if (persona.painPoints != null) {
        await CommonTest.dragUntil(
          tester,
          key: 'painPoints',
          listViewName: 'personaDetailListView',
        );
        expect(
          CommonTest.getTextFormField('painPoints'),
          equals(persona.painPoints!),
        );
      }

      if (persona.goals != null) {
        await CommonTest.dragUntil(
          tester,
          key: 'goals',
          listViewName: 'personaDetailListView',
        );
        expect(
          CommonTest.getTextFormField('goals'),
          equals(persona.goals!),
        );
      }

      if (persona.toneOfVoice != null) {
        await CommonTest.dragUntil(
          tester,
          key: 'toneOfVoice',
          listViewName: 'personaDetailListView',
        );
        expect(
          CommonTest.getTextFormField('toneOfVoice'),
          equals(persona.toneOfVoice!),
        );
      }

      await CommonTest.tapByKey(tester, 'cancel');
    }
    await clearSearch(tester);
  }
}
