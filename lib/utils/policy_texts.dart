class PolicyDoc {
  const PolicyDoc({
    required this.key,
    required this.title,
    required this.version,
    required this.body,
  });

  final String key;
  final String title;
  final String version;
  final String body;
}

const policyPlaceholders = '''
Placeholders to replace before publishing:
Registered office: [Registered office address]
Website: https://www.paarisetu.example
Legal / privacy: privacy@paarisetu.example
Grievance officer: [Name, contact]
Security: security@paarisetu.example
Billing: billing@paarisetu.example

These are product drafts. An Indian lawyer should review them against the DPDP Act, 2023 and your live payment gateway before you publish.
''';

const policyDocuments = <PolicyDoc>[
  PolicyDoc(
    key: 'terms',
    title: 'Terms & Conditions',
    version: '1.0',
    body:
        'Paarisetu provides a family digital vault. The account holder is responsible for people they invite and documents they upload. Subscription limits apply to the family, not each invited user. Cancel-at-period-end keeps view/download and blocks new consumption. Do not upload unlawful content. We may suspend accounts that abuse the service.\n\n$policyPlaceholders',
  ),
  PolicyDoc(
    key: 'privacy',
    title: 'Privacy Policy',
    version: '1.0',
    body:
        'Paarisetu processes personal data to create your account, store family documents, organise the vault, send reminders, and (if you allow it) run OCR/AI search. The account holder is often not the only data subject — a vault may hold documents about family members. We store documents encrypted. AI processing is optional and can be withdrawn in Settings → Privacy & Data. You may export metadata or delete your account.\n\nThis draft should be aligned with the Digital Personal Data Protection Act, 2023 and the 2025 Rules before publication.\n\n$policyPlaceholders',
  ),
  PolicyDoc(
    key: 'subscription',
    title: 'Subscription, Payment, Cancellation & Refund',
    version: '1.0',
    body:
        'Plans control storage, document count, members, devices, OCR and AI question caps. Payments go through the configured gateway. Cancellation is at period end: existing documents remain readable; new uploads, invites and devices are blocked. Refunds follow the gateway and plan terms you actually ship.\n\n$policyPlaceholders',
  ),
  PolicyDoc(
    key: 'retention',
    title: 'Data Retention & Deletion',
    version: '1.0',
    body:
        'Active documents stay until you delete them. Soft-deleted documents are retained for the published retention window, then eligible for permanent deletion. Account deletion removes or anonymises account data subject to legal hold. Consent records are kept so we know which policy version you accepted.\n\n$policyPlaceholders',
  ),
  PolicyDoc(
    key: 'security',
    title: 'Security & Responsible Disclosure',
    version: '1.0',
    body:
        'Documents are encrypted at rest. Report vulnerabilities to [Security email]. Do not test other customers’ accounts. We will acknowledge valid reports and work to fix them.\n\n$policyPlaceholders',
  ),
  PolicyDoc(
    key: 'cookies',
    title: 'Cookie & Tracking Policy',
    version: '1.0',
    body:
        'The mobile app uses device identifiers for login security. Website cookies, if any, will be described here. Analytics is optional and can be withdrawn in Privacy & Data.\n\n$policyPlaceholders',
  ),
  PolicyDoc(
    key: 'aup',
    title: 'Acceptable Use & Disclaimer',
    version: '1.0',
    body:
        'You may only upload information you are authorised to manage. Paarisetu is not a substitute for legal, tax or medical advice. AI answers can be incomplete — verify important dates in the original document.\n\n$policyPlaceholders',
  ),
];

PolicyDoc policyByKey(String key) {
  return policyDocuments.firstWhere(
    (p) => p.key == key,
    orElse: () => policyDocuments.first,
  );
}
