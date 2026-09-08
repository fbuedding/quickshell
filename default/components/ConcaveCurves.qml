import QtQuick
import QtQuick.Shapes
import "../theme"

Shape {
    id: root

    property int radius: Theme.cornerRadius
    property color color: Colors.colBg
    property bool isTop: true
    property bool mirrored: false   // true = horizontally flip (for right-side bars)
    property int borderWidth: 0
    property color borderColor: "transparent"

    implicitWidth: radius
    implicitHeight: radius

    preferredRendererType: Shape.CurveRenderer

    transform: Scale {
	xScale: root.mirrored ? -1 : 1
	origin.x: root.radius / 2
	origin.y: 0
    }

    ShapePath {
	fillColor: root.color
	strokeColor: "transparent"

	startX: root.isTop ? root.radius : 0
	startY: root.isTop ? 0 : 0

	PathLine {
	    x: 0
	    y: root.isTop ? 0 : root.radius
	}

	PathLine {
	    x: root.isTop ? 0 : root.radius
	    y: root.isTop ? root.radius : root.radius
	}

	PathArc {
	    x: root.isTop ? root.radius : 0
	    y: root.isTop ? 0 : 0
	    radiusX: root.radius
	    radiusY: root.radius
	    direction: PathArc.Clockwise
	}
    }

    // Border along the curved arc
    ShapePath {
	fillColor: "transparent"
	strokeColor: root.borderWidth > 0 ? root.borderColor : "transparent"
	strokeWidth: root.borderWidth

	startX: root.isTop ? 0 : root.radius
	startY: root.isTop ? root.radius : root.radius

	PathArc {
	    x: root.isTop ? root.radius : 0
	    y: 0
	    radiusX: root.radius
	    radiusY: root.radius
	    direction: PathArc.Clockwise
	}
    }
}

