/*
 * Moqui MCP Widget Description System
 *
 * Describes Moqui UI elements in a structured format for LLMs to understand and interact with.
 * Instead of rendering visual markup (markdown tables), we describe each widget semantically.
 */

// Widget type constants
class WidgetType {
    static final String FORM = 'form'
    static final String FORM_SINGLE = 'form-single'
    static final String FORM_LIST = 'form-list'
    static final String FORM_FIELD = 'field'
    static final String BUTTON = 'button'
    static final String LINK = 'link'
    static final String DISPLAY = 'display'
    static final String CHECK = 'check'
    static final String TEXT_LINE = 'text-line'
    static final String DATE_TIME = 'date-time'
    static final String LABEL = 'label'
    static final String SECTION = 'section'
    static final String CONTAINER = 'container'
    static final String SUBSCREENS_MENU = 'subscreens-menu'
}

// Data types
class DataType {
    static final String STRING = 'string'
    static final String NUMBER = 'number'
    static final String CURRENCY = 'currency'
    static final String DATE = 'date'
    static final String DATE_TIME = 'datetime'
    static final String BOOLEAN = 'boolean'
    static final String ENUM = 'enum'
}

/**
 * Widget description for LLM consumption
 */
class WidgetDescription {
    static Map description(formName, widgets) {
        return [
            type: WidgetType.FORM,
            name: formName,
            widgets: widgets
        ]
    }

    static Map formField(name, type, value, Map options = [:]) {
        return [
            type: WidgetType.FORM_FIELD,
            name: name,
            dataType: type,
            value: value
        ] + options
    }

    static Map button(text, action, Map parameters = [:]) {
        return [
            type: WidgetType.BUTTON,
            text: text,
            action: action,
            parameters: parameters
        ]
    }

    static Map link(text, action, Map parameters = [:]) {
        return [
            type: WidgetType.LINK,
            text: text,
            action: action,
            parameters: parameters
        ]
    }

    static Map display(text, value) {
        return [
            type: WidgetType.DISPLAY,
            text: text,
            value: value
        ]
    }

    static Map label(text) {
        return [
            type: WidgetType.LABEL,
            text: text
        ]
    }

    static Map formList(formName, columns, rows, List actions = []) {
        return [
            type: WidgetType.FORM_LIST,
            name: formName,
            columns: columns,
            rows: rows,
            actions: actions
        ]
    }

    static Map column(name, header, fieldType, Map options = [:]) {
        return [
            name: name,
            header: header,
            fieldType: fieldType
        ] + options
    }

    static Map row(values, List actions = []) {
        return [
            values: values,
            actions: actions
        ]
    }
}
