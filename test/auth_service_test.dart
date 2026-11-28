import 'package:flutter_quiz_app/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DemoAuthService service({
    AuthConfig config = const AuthConfig(demoEnabled: true),
    MemoryAuthStore? store,
  }) => DemoAuthService(config: config, store: store ?? MemoryAuthStore());

  group('DemoAuthService – tài khoản mẫu', () {
    test('đăng nhập demo thành công với đúng email/mật khẩu', () async {
      final store = MemoryAuthStore();
      final user = await service(store: store)
          .signIn(email: 'demo@example.com', password: 'Demo123!');
      expect(user.email, 'demo@example.com');
      expect(user.name, 'Demo User');
      // Tài khoản mẫu không được ghi vào kho tài khoản.
      expect(await store.loadAccounts(), isEmpty);
    });

    test('đăng nhập demo sai mật khẩu ném invalidCredentials', () async {
      await expectLater(
        service().signIn(email: 'demo@example.com', password: 'sai-mat-khau'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.failure,
            'failure',
            AuthFailure.invalidCredentials,
          ),
        ),
      );
    });

    test(
      'email chưa đăng ký ném invalidCredentials (không lộ email tồn tại)',
      () async {
        await expectLater(
          service().signIn(email: 'nguoi-la@example.com', password: 'Demo123!'),
          throwsA(
            isA<AuthException>().having(
              (e) => e.failure,
              'failure',
              AuthFailure.invalidCredentials,
            ),
          ),
        );
      },
    );
  });

  group('DemoAuthService – đăng ký', () {
    test('đăng ký rồi đăng nhập lại thành công', () async {
      final store = MemoryAuthStore();
      final svc = service(store: store);
      final user = await svc.signUp(
        name: 'Nguyễn Văn An',
        email: 'An@Example.com',
        password: 'MatKhau123!',
      );
      expect(user.name, 'Nguyễn Văn An');
      expect(user.email, 'an@example.com');

      final loggedIn = await svc.signIn(
        email: 'AN@example.com',
        password: 'MatKhau123!',
      );
      expect(loggedIn.email, 'an@example.com');
    });

    test('không lưu mật khẩu dạng văn bản trong kho tài khoản', () async {
      const password = 'MatKhau123!';
      final store = MemoryAuthStore();
      await service(store: store).signUp(
        name: 'Nguyễn Văn An',
        email: 'an@example.com',
        password: password,
      );
      final accounts = await store.loadAccounts();
      expect(accounts, hasLength(1));
      final account = accounts.single;
      expect(account.passwordHash, isNot(password));
      expect(account.passwordHash, isNotEmpty);
      expect(account.salt, isNotEmpty);
      // Chuỗi mật khẩu gốc không xuất hiện trong dữ liệu lưu.
      expect(account.toJson().toString(), isNot(contains(password)));
    });

    test('email trùng ném emailInUse', () async {
      final svc = service();
      await svc.signUp(
        name: 'A',
        email: 'an@example.com',
        password: 'MatKhau123!',
      );
      await expectLater(
        svc.signUp(name: 'B', email: 'an@example.com', password: 'MatKhau123!'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.failure,
            'failure',
            AuthFailure.emailInUse,
          ),
        ),
      );
    });

    test('email trùng với tài khoản mẫu ném emailInUse', () async {
      await expectLater(
        service().signUp(
          name: 'A',
          email: 'demo@example.com',
          password: 'MatKhau123!',
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.failure,
            'failure',
            AuthFailure.emailInUse,
          ),
        ),
      );
    });

    test('email không hợp lệ ném invalidEmail', () async {
      await expectLater(
        service().signUp(
          name: 'A',
          email: 'khong-hop-le',
          password: 'MatKhau123!',
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.failure,
            'failure',
            AuthFailure.invalidEmail,
          ),
        ),
      );
    });

    test('mật khẩu ngắn ném weakPassword', () async {
      await expectLater(
        service().signUp(
          name: 'A',
          email: 'an@example.com',
          password: '1234567',
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.failure,
            'failure',
            AuthFailure.weakPassword,
          ),
        ),
      );
    });

    test('thiếu họ tên ném missingName', () async {
      await expectLater(
        service().signUp(
          name: '   ',
          email: 'an@example.com',
          password: 'MatKhau123!',
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.failure,
            'failure',
            AuthFailure.missingName,
          ),
        ),
      );
    });
  });

  group('DemoAuthService – phiên đăng nhập', () {
    test('Ghi nhớ đăng nhập lưu phiên; không ghi nhớ thì không', () async {
      final store = MemoryAuthStore();
      final svc = service(store: store);

      await svc.signIn(
        email: 'demo@example.com',
        password: 'Demo123!',
        remember: true,
      );
      expect(await svc.restoreSession(), isNotNull);

      await svc.signOut();
      expect(await svc.restoreSession(), isNull);

      await svc.signIn(
        email: 'demo@example.com',
        password: 'Demo123!',
        remember: false,
      );
      expect(await svc.restoreSession(), isNull);
    });

    test('đăng xuất xoá phiên đã ghi nhớ', () async {
      final store = MemoryAuthStore();
      final svc = service(store: store);
      await svc.signIn(
        email: 'demo@example.com',
        password: 'Demo123!',
        remember: true,
      );
      expect(await store.loadSessionEmail(), 'demo@example.com');
      await svc.signOut();
      expect(await store.loadSessionEmail(), isNull);
    });
  });

  group('DemoAuthService – Google và chế độ demo', () {
    test('signInWithGoogle không giả mạo thành công', () async {
      await expectLater(
        service().signInWithGoogle(),
        throwsA(
          isA<AuthException>().having(
            (e) => e.failure,
            'failure',
            AuthFailure.googleNotConfigured,
          ),
        ),
      );
    });

    test('tắt chế độ demo thì tài khoản mẫu không còn dùng được', () async {
      final svc = service(config: const AuthConfig(demoEnabled: false));
      expect(svc.demoEmail, isNull);
      expect(svc.isDemoAccount('demo@example.com'), isFalse);
      await expectLater(
        svc.signIn(email: 'demo@example.com', password: 'Demo123!'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.failure,
            'failure',
            AuthFailure.disabled,
          ),
        ),
      );
    });
  });

  group('DemoAuthService – hồ sơ', () {
    test('cập nhật họ tên/ảnh đại diện và đọc lại sau khi restore', () async {
      final store = MemoryAuthStore();
      final svc = service(store: store);
      final user = await svc.signUp(
        name: 'Nguyễn Văn An',
        email: 'an@example.com',
        password: 'MatKhau123!',
      );
      final updated = await svc.updateProfile(
        user.copyWith(name: 'An Nguyễn', avatarBase64: 'aGVsbG8='),
      );
      expect(updated.name, 'An Nguyễn');
      expect(updated.hasAvatar, isTrue);

      final restored = await svc.restoreSession();
      expect(restored!.name, 'An Nguyễn');
      expect(restored.hasAvatar, isTrue);
    });

    test('xoá ảnh đại diện quay về ảnh mặc định', () async {
      final store = MemoryAuthStore();
      final svc = service(store: store);
      final user = await svc.signUp(
        name: 'Nguyễn Văn An',
        email: 'an@example.com',
        password: 'MatKhau123!',
      );
      await svc.updateProfile(user.copyWith(avatarBase64: 'aGVsbG8='));
      final cleared = await svc.updateProfile(user.copyWith(clearAvatar: true));
      expect(cleared.hasAvatar, isFalse);
      expect((await svc.restoreSession())!.hasAvatar, isFalse);
    });
  });
}
