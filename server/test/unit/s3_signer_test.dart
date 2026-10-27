import 'package:ebucard_server/src/storage/s3_signer.dart';
import 'package:test/test.dart';

void main() {
  test('matches the AWS SigV4 "GET Object" example', () {
    // From the AWS S3 docs, "Example: GET Object" (header-based auth).
    const signer = S3Signer(
      accessKey: 'AKIAIOSFODNN7EXAMPLE',
      secretKey: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
      region: 'us-east-1',
    );
    final headers = signer.sign(
      method: 'GET',
      uri: Uri.parse('https://examplebucket.s3.amazonaws.com/test.txt'),
      headers: {
        'host': 'examplebucket.s3.amazonaws.com',
        'range': 'bytes=0-9',
      },
      payloadHash: emptyPayloadHash,
      now: DateTime.utc(2013, 5, 24),
    );
    expect(
      headers['authorization'],
      'AWS4-HMAC-SHA256 '
      'Credential=AKIAIOSFODNN7EXAMPLE/20130524/us-east-1/s3/aws4_request, '
      'SignedHeaders=host;range;x-amz-content-sha256;x-amz-date, '
      'Signature='
      'f0e8bdb87c964420e857bd35b5d6ed310bd44f0170aba48dd91039c6036bdb41',
    );
    expect(headers['x-amz-date'], '20130524T000000Z');
  });
}
