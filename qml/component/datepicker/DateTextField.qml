pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Templates as T
import Qcm.Material as MD

MD.TextField {
    id: control

    property var value: null
    property string dateFormat: "yyyy-MM-dd"
    property var minDate: null
    property var maxDate: null
    property bool allowEmpty: false
    property bool popupUnderField: true

    signal modified(date d)

    readonly property bool isEuropeanFormat: dateFormat.indexOf("dd") === 0

    placeholderText: dateFormat
    inputMethodHints: Qt.ImhDate
    selectByMouse: true
    type: MD.Enum.TextFieldOutlined

    validator: RegularExpressionValidator {
        regularExpression: control.isEuropeanFormat
                ? /^\d{1,2}\.\d{1,2}\.\d{4}$/
                : /^\d{4}[-/]\d{1,2}[-/]\d{1,2}$/
    }

    function _isValidDate(d) {
        return d instanceof Date && !isNaN(d.getTime())
    }

    function _currentDateOrToday() {
        return _isValidDate(value) ? value : new Date()
    }

    function _inBounds(d) {
        if (!d)
            return allowEmpty
        if (minDate && d.getTime() < minDate.getTime())
            return false
        if (maxDate && d.getTime() > maxDate.getTime())
            return false
        return true
    }

    function _makeDate(year, month, day) {
        if (month < 0 || month > 11 || day < 1 || day > 31)
            return undefined
        const d = new Date(year, month, day)
        if (d.getFullYear() !== year || d.getMonth() !== month || d.getDate() !== day)
            return undefined
        return d
    }

    function syncDisplayFromValue() {
        if (allowEmpty && !_isValidDate(value))
            text = ""
        else
            text = Qt.formatDate(_currentDateOrToday(), dateFormat)
    }

    function setDate(d) {
        if (!_isValidDate(d))
            return
        value = d
        syncDisplayFromValue()
    }

    function clearDate() {
        if (!allowEmpty)
            return
        value = null
        syncDisplayFromValue()
    }

    function openDatePicker() {
        m_picker.selectedDate = _currentDateOrToday()
        m_picker.minDate = control.minDate
        m_picker.maxDate = control.maxDate
        m_picker.month = m_picker.selectedDate.getMonth()
        m_picker.year = m_picker.selectedDate.getFullYear()
        pickerPopup.open()
    }

    function _parse(s) {
        const raw = ("" + s).trim()
        if (!raw.length)
            return allowEmpty ? null : undefined

        if (isEuropeanFormat) {
            const m = raw.match(/^(\d{1,2})\.(\d{1,2})\.(\d{4})$/)
            if (!m)
                return undefined
            return _makeDate(parseInt(m[3], 10), parseInt(m[2], 10) - 1, parseInt(m[1], 10))
        }

        const m = raw.replace(/\//g, "-").match(/^(\d{4})-(\d{1,2})-(\d{1,2})$/)
        if (!m)
            return undefined
        return _makeDate(parseInt(m[1], 10), parseInt(m[2], 10) - 1, parseInt(m[3], 10))
    }

    Component.onCompleted: syncDisplayFromValue()
    onValueChanged: syncDisplayFromValue()

    onEditingFinished: {
        const d = _parse(text)
        if (d === null && allowEmpty) {
            value = null
            modified(null)
            return
        }
        if (d && _inBounds(d)) {
            value = d
            modified(d)
            syncDisplayFromValue()
            return
        }
        syncDisplayFromValue()
    }

    trailing: MD.SmallIconButton {
        anchors.right: parent?.right
        anchors.verticalCenter: parent?.verticalCenter
        anchors.rightMargin: 8
        icon.name: MD.Token.icon.calendar_today
        onClicked: control.openDatePicker()
    }

    Popup {
        id: pickerPopup
        modal: true
        focus: true
        padding: 0
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        parent: control.Window && control.Window.contentItem
                ? control.Window.contentItem : T.Overlay.overlay

        implicitWidth: pickerColumn.implicitWidth + 16
        implicitHeight: pickerColumn.implicitHeight + 16

        onAboutToShow: {
            const host = parent
            if (!host || control.width <= 0)
                return
            const p = control.mapToItem(host, 0, control.height)
            const edge = 8
            let nx = p.x
            let ny = p.y + 4
            if (nx + width > host.width - edge)
                nx = Math.max(edge, host.width - edge - width)
            if (nx < edge)
                nx = edge
            if (ny + height > host.height - edge)
                ny = Math.max(edge, p.y - height - 4)
            x = nx
            y = ny
        }

        background: MD.ElevationRectangle {
            radius: MD.Token.shape.corner.large
            color: MD.MProp.color.surface_container_high
            elevation: MD.Token.elevation.level3
        }

        contentItem: Item {
            implicitWidth: pickerColumn.implicitWidth
            implicitHeight: pickerColumn.implicitHeight

            Column {
                id: pickerColumn
                anchors.centerIn: parent
                spacing: 0

                MD.DatePicker {
                    id: m_picker
                    showHeader: false
                    selectionMode: MD.DatePicker.SelectionMode.Single
                }

                RowLayout {
                    width: m_picker.implicitWidth
                    spacing: 8
                    Item { Layout.fillWidth: true }

                    MD.Button {
                        text: qsTr("Отмена")
                        mdState.type: MD.Enum.BtText
                        onClicked: pickerPopup.close()
                    }

                    MD.Button {
                        text: qsTr("OK")
                        mdState.type: MD.Enum.BtFilled
                        onClicked: {
                            const d = m_picker.selectedDate
                            if (_inBounds(d)) {
                                control.setDate(d)
                                control.modified(d)
                            }
                            pickerPopup.close()
                        }
                    }
                }
            }
        }
    }
}
