"""A minimal fake Firestore client shared by the orchestration-level tests.

Only implements the exact surface firestore_io.py actually calls
(collection_group().where()/.stream(), doc.reference.parent.parent.id) —
not a general Firestore emulator.
"""

from types import SimpleNamespace


def _make_ref(uid: str):
    # doc.reference.parent.parent.id: parent = the collection, parent.parent
    # = the users/{uid} document reference, whose id is the uid.
    return SimpleNamespace(parent=SimpleNamespace(parent=SimpleNamespace(id=uid)))


class _FakeSnapshot:
    def __init__(self, doc_id: str, uid: str, data: dict):
        self.id = doc_id
        self._data = data
        self.reference = _make_ref(uid)

    def to_dict(self):
        return dict(self._data)


class _FakeQuery:
    def __init__(self, docs: list[dict]):
        self._docs = docs

    def where(self, field=None, op=None, value=None, *, filter=None):  # noqa: A002
        # Accepts both the legacy positional form and the FieldFilter keyword
        # form the real client now wants, so this fake keeps matching whichever
        # firestore_io actually uses.
        if filter is not None:
            field, op, value = filter.field_path, filter.op_string, filter.value

        if op == "in":
            filtered = [d for d in self._docs if d["data"].get(field) in value]
        elif op == "==":
            filtered = [d for d in self._docs if d["data"].get(field) == value]
        else:
            raise NotImplementedError(op)
        return _FakeQuery(filtered)

    def stream(self):
        for d in self._docs:
            yield _FakeSnapshot(d["id"], d["uid"], d["data"])


class FakeDb:
    """docs shape: [{"id": "p1", "uid": "u1", "data": {...fields...}}, ...]"""

    def __init__(self, positions: list[dict] | None = None, price_alerts: list[dict] | None = None):
        self._positions = positions or []
        self._price_alerts = price_alerts or []

    def collection_group(self, name: str):
        if name == "positions":
            return _FakeQuery(self._positions)
        if name == "price_alerts":
            return _FakeQuery(self._price_alerts)
        raise NotImplementedError(name)
