# SPDX-License-Identifier: LGPL-3.0-or-later

from typing import TYPE_CHECKING, Any, Dict, Optional

from ..pyotherside_events import ModelItemSet
from ..utils import serialize_value_for_qml

if TYPE_CHECKING:
    from .model import Model


class ModelItem:
    """Base class for items stored inside a `Model`.

    This class must be subclassed and not used directly.
    All subclasses must be dataclasses.

    Subclasses are also expected to implement `__lt__()`,
    to provide support for comparisons with the `<`, `>`, `<=`, `=>` operators
    and thus allow a `Model` to keep its data sorted.
    """

    def __new__(cls, *_args, **_kwargs) -> "ModelItem":
        cls.parent_model: Optional[Model] = None
        return super().__new__(cls)


    def __setattr__(self, name: str, value) -> None:
        """If this item is in a `Model`, alert it of attribute changes."""

        if self.parent_model is None:
            super().__setattr__(name, value)
            return

        if getattr(self, name) == value:
            return

        if not self.can_serialize_field(name):
            super().__setattr__(name, value)
            return

        with self.parent_model._write_lock:
            super().__setattr__(name, value)
            self.parent_model.__setitem__(  # type: ignore
                self.id,  # type: ignore
                self,
                {name: self.serialize_field(name)},
            )


    def __delattr__(self, name: str) -> None:
        raise NotImplementedError()


    def can_serialize_field(self, field: str) -> Any:
        return (
            not field.startswith("_") and
            field not in (
                "parent_model", "serialized",
                "serialize_field", "can_serialize_field",
            )
        )


    def serialize_field(self, field: str) -> Any:
        return serialize_value_for_qml(
            getattr(self, field),
            json_list_dicts=True,
        )


    @property
    def serialized(self) -> Dict[str, Any]:
        """Return this item as a dict ready to be passed to QML."""

        return {
            name: self.serialize_field(name) for name in dir(self)
            if self.can_serialize_field(name)
        }
