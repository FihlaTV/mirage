# SPDX-License-Identifier: LGPL-3.0-or-later

from dataclasses import dataclass, field
from typing import TYPE_CHECKING, Any, Optional

import pyotherside

from .utils import serialize_value_for_qml

if TYPE_CHECKING:
    from .models import SyncId
    from .models.model_item import ModelItem


@dataclass
class PyOtherSideEvent:
    """Event that will be sent on instanciation to QML by PyOtherSide."""

    def __post_init__(self) -> None:
        # XXX: CPython 3.6 or any Python implemention >= 3.7 is required for
        # correct __dataclass_fields__ dict order.
        args = [
            serialize_value_for_qml(getattr(self, field))
            for field in self.__dataclass_fields__  # type: ignore
            if field != "callbacks"
        ]
        pyotherside.send(type(self).__name__, *args)


@dataclass
class ExitRequested(PyOtherSideEvent):
    """Request for the application to exit."""

    exit_code: int = 0


@dataclass
class AlertRequested(PyOtherSideEvent):
    """Request a window manager alert to be shown.

    Sets the urgency hint for compliant X11/Wayland window managers;
    flashes the taskbar icon on Windows.
    """


@dataclass
class CoroutineDone(PyOtherSideEvent):
    """Indicate that an asyncio coroutine finished."""

    uuid:      str                 = field()
    result:    Any                 = None
    exception: Optional[Exception] = None
    traceback: Optional[str]       = None


@dataclass
class LoopException(PyOtherSideEvent):
    """Indicate an uncaught exception occurance in the asyncio loop."""

    message:   str                 = field()
    exception: Optional[Exception] = field()
    traceback: Optional[str]       = None


@dataclass
class ModelEvent(PyOtherSideEvent):
    """Base class for model change events."""

    sync_id: "SyncId" = field()


@dataclass
class ModelItemInserted(ModelEvent):
    """Indicate a `ModelItem` insertion into a `Backend` `Model`."""

    index: int         = field()
    item:  "ModelItem" = field()


@dataclass
class ModelItemFieldChanged(ModelEvent):
    """Indicate a `ModelItem`'s field value change in a `Backend` `Model`."""

    item_index_then: int = field()
    item_index_now:  int = field()
    changed_field:   str = field()
    field_value:     Any = field()


@dataclass
class ModelItemDeleted(ModelEvent):
    """Indicate the removal of a `ModelItem` from a `Backend` `Model`."""

    index: int = field()


@dataclass
class ModelCleared(ModelEvent):
    """Indicate that a `Backend` `Model` was cleared."""
