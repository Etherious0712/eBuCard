import 'package:ebucard_models/ebucard_models.dart';
import 'package:test/test.dart';

BusinessCard _card({
  String fullName = 'Tai Man Chan',
  List<LabeledValue> phones = const [],
  List<LabeledValue> emails = const [],
  String? photoUrl,
}) => BusinessCard(
  id: 'c1',
  cardName: 'Work',
  fullName: fullName,
  phones: phones,
  emails: emails,
  photoUrl: photoUrl,
  updatedAt: DateTime.utc(2026),
);

const _phone = LabeledValue(
  label: ContactLabel.mobile,
  value: '+852 9123 4567',
);
const _email = LabeledValue(label: ContactLabel.work, value: 'tm@example.com');

void main() {
  group('validateCard', () {
    test('name plus a phone or an email is valid', () {
      expect(validateCard(_card(phones: [_phone])), isEmpty);
      expect(validateCard(_card(emails: [_email])), isEmpty);
    });

    test('full name is required', () {
      expect(validateCard(_card(fullName: '  ', phones: [_phone])), {
        CardValidationError.fullNameRequired,
      });
    });

    test('blank phones and emails do not count', () {
      const blank = LabeledValue(label: ContactLabel.work, value: ' ');
      expect(validateCard(_card(phones: [blank])), {
        CardValidationError.phoneOrEmailRequired,
      });
    });

    test('malformed email is rejected', () {
      const bad = LabeledValue(label: ContactLabel.work, value: 'tm@');
      expect(validateCard(_card(phones: [_phone], emails: [bad])), {
        CardValidationError.invalidEmail,
      });
    });
  });

  group('VCardEncoder images', () {
    const encoder = VCardEncoder();

    test('local file photos are never put in the vCard', () {
      final v = encoder.encode(
        _card(phones: [_phone], photoUrl: 'file:///data/photo.jpg'),
      );
      expect(v, isNot(contains('PHOTO')));
    });

    test('remote photos are referenced by URL', () {
      final v = encoder.encode(
        _card(phones: [_phone], photoUrl: 'https://cdn.example.com/p.jpg'),
      );
      expect(v, contains('PHOTO;VALUE=URI:https://cdn.example.com/p.jpg'));
    });
  });
}
