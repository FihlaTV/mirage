# SPDX-License-Identifier: LGPL-3.0-or-later

from typing import TYPE_CHECKING

from . import SyncId
from .items import Account, AccountOrRoom, Room
from .model import Model

if TYPE_CHECKING:
    from ..backend import Backend
    from .model_item import ModelItem


class ModelProxy(Model):
    def __init__(self, sync_id: SyncId) -> None:
        super().__init__(sync_id)
        Model.proxies[sync_id] = self


    def accept_source(self, source: Model) -> bool:
        return True


    def convert_item(self, item: "ModelItem") -> "ModelItem":
        return item


    def converted_index(self, item_id: str) -> int:
        for i, item in enumerate(self._sorted_data):
            if item.id == item_id:  # type: ignore
                return i

        raise ValueError(f"{item_id} not found in _sorted_data")


    def source_item_set(self, source: Model, key, value: "ModelItem") -> None:
        if self.accept_source(source):
            self[source.sync_id, key] = self.convert_item(value)


    def source_item_deleted(self, source: Model, key) -> None:
        if self.accept_source(source):
            del self[source.sync_id, key]


    def source_cleared(self, source: Model) -> None:
        if self.accept_source(source):
            for source_sync_id, key in self.copy():
                if source_sync_id == source.sync_id:
                    del self[source_sync_id, key]


class AccountRooms(ModelProxy):
    def __init__(self, backend: "Backend") -> None:
        super().__init__(sync_id="account_rooms")
        self.backend = backend


    def accept_source(self, source: Model) -> bool:
        return source.sync_id == "accounts" or (
            # is account rooms source
            isinstance(source.sync_id, tuple) and
            len(source.sync_id) == 2 and
            source.sync_id[1] == "rooms"  # type: ignore
        )


    def convert_item(self, item: "ModelItem") -> AccountOrRoom:
        if not isinstance(item, (Account, Room)):
            raise TypeError()

        return AccountOrRoom.from_item(item, self.backend)
