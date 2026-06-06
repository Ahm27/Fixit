enum AccountRole { customer, worker }

extension AccountRoleX on AccountRole {
  String get label => this == AccountRole.customer ? 'Customer' : 'Worker';
  String get dbValue => this == AccountRole.customer ? 'customer' : 'worker';

  static AccountRole fromDb(String value) {
    return value == 'worker' ? AccountRole.worker : AccountRole.customer;
  }
}
