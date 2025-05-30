"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.GraphWebviewProvider = void 0;
const vscode = __importStar(require("vscode"));
class GraphWebviewProvider {
    constructor(extensionUri) {
        this.extensionUri = extensionUri;
    }
    getHtmlForWebview(webview, dependencies) {
        const d3Uri = webview.asWebviewUri(vscode.Uri.joinPath(this.extensionUri, 'node_modules', 'd3', 'dist', 'd3.min.js'));
        return `<!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Code Dependency Graph</title>
            <style>
                body {
                    margin: 0;
                    padding: 0;
                    overflow: hidden;
                    font-family: Arial, sans-serif;
                    background-color: var(--vscode-editor-background);
                    color: var(--vscode-editor-foreground);
                }
                
                #graph {
                    width: 100vw;
                    height: 100vh;
                }
                
                .node {
                    cursor: pointer;
                }
                
                .node circle {
                    stroke: var(--vscode-editor-foreground);
                    stroke-width: 2px;
                }
                
                .node.python circle {
                    fill: #3776ab;
                }
                
                .node.javascript circle {
                    fill: #f7df1e;
                }
                
                .node.typescript circle {
                    fill: #3178c6;
                }
                
                .node.entry-point circle {
                    stroke: #ff6b6b;
                    stroke-width: 4px;
                }
                
                .node text {
                    font-size: 12px;
                    fill: var(--vscode-editor-foreground);
                    pointer-events: none;
                }
                
                .link {
                    stroke: var(--vscode-editor-foreground);
                    stroke-opacity: 0.6;
                    fill: none;
                    marker-end: url(#arrowhead);
                }
                
                .link:hover {
                    stroke-opacity: 1;
                    stroke-width: 2px;
                }
                
                #info {
                    position: absolute;
                    top: 10px;
                    right: 10px;
                    background: var(--vscode-editor-background);
                    border: 1px solid var(--vscode-panel-border);
                    padding: 10px;
                    border-radius: 5px;
                    max-width: 300px;
                }
                
                #controls {
                    position: absolute;
                    top: 10px;
                    left: 10px;
                    background: var(--vscode-editor-background);
                    border: 1px solid var(--vscode-panel-border);
                    padding: 10px;
                    border-radius: 5px;
                }
                
                button {
                    background: var(--vscode-button-background);
                    color: var(--vscode-button-foreground);
                    border: none;
                    padding: 5px 10px;
                    margin: 2px;
                    cursor: pointer;
                    border-radius: 3px;
                }
                
                button:hover {
                    background: var(--vscode-button-hoverBackground);
                }
                
                .tooltip {
                    position: absolute;
                    text-align: center;
                    padding: 5px;
                    font-size: 12px;
                    background: var(--vscode-editorWidget-background);
                    border: 1px solid var(--vscode-editorWidget-border);
                    border-radius: 3px;
                    pointer-events: none;
                    opacity: 0;
                }
            </style>
        </head>
        <body>
            <svg id="graph"></svg>
            <div id="controls">
                <button onclick="resetZoom()">Reset Zoom</button>
                <button onclick="centerGraph()">Center Graph</button>
                <button onclick="toggleLabels()">Toggle Labels</button>
            </div>
            <div id="info">
                <h3>Dependency Graph</h3>
                <p>Entry Point: <strong>${dependencies.entryPoint}</strong></p>
                <p>Total Files: <strong>${dependencies.nodes.length}</strong></p>
                <p>Total Dependencies: <strong>${dependencies.edges.length}</strong></p>
            </div>
            <div class="tooltip"></div>
            
            <script src="${d3Uri}"></script>
            <script>
                const data = ${JSON.stringify(dependencies)};
                let showLabels = true;
                
                // Set up the SVG
                const width = window.innerWidth;
                const height = window.innerHeight;
                
                const svg = d3.select("#graph")
                    .attr("width", width)
                    .attr("height", height);
                
                // Add arrow marker
                svg.append("defs").append("marker")
                    .attr("id", "arrowhead")
                    .attr("viewBox", "-0 -5 10 10")
                    .attr("refX", 20)
                    .attr("refY", 0)
                    .attr("orient", "auto")
                    .attr("markerWidth", 8)
                    .attr("markerHeight", 8)
                    .append("svg:path")
                    .attr("d", "M 0,-5 L 10,0 L 0,5")
                    .attr("fill", getComputedStyle(document.body).getPropertyValue('--vscode-editor-foreground'));
                
                // Create zoom behavior
                const zoom = d3.zoom()
                    .scaleExtent([0.1, 4])
                    .on("zoom", (event) => {
                        g.attr("transform", event.transform);
                    });
                
                svg.call(zoom);
                
                const g = svg.append("g");
                
                // Create force simulation
                const simulation = d3.forceSimulation(data.nodes)
                    .force("link", d3.forceLink(data.edges).id(d => d.id).distance(100))
                    .force("charge", d3.forceManyBody().strength(-300))
                    .force("center", d3.forceCenter(width / 2, height / 2))
                    .force("collision", d3.forceCollide().radius(30));
                
                // Create links
                const link = g.append("g")
                    .selectAll("line")
                    .data(data.edges)
                    .enter().append("line")
                    .attr("class", "link");
                
                // Create nodes
                const node = g.append("g")
                    .selectAll("g")
                    .data(data.nodes)
                    .enter().append("g")
                    .attr("class", d => {
                        let classes = "node " + d.type;
                        if (d.id === data.entryPoint) {
                            classes += " entry-point";
                        }
                        return classes;
                    })
                    .call(d3.drag()
                        .on("start", dragstarted)
                        .on("drag", dragged)
                        .on("end", dragended));
                
                // Add circles to nodes
                node.append("circle")
                    .attr("r", d => d.id === data.entryPoint ? 15 : 10);
                
                // Add labels to nodes
                const labels = node.append("text")
                    .text(d => d.label)
                    .attr("x", 15)
                    .attr("y", 5);
                
                // Add tooltip
                const tooltip = d3.select(".tooltip");
                
                node.on("mouseover", (event, d) => {
                    tooltip.transition()
                        .duration(200)
                        .style("opacity", .9);
                    tooltip.html(d.fullPath)
                        .style("left", (event.pageX + 10) + "px")
                        .style("top", (event.pageY - 28) + "px");
                })
                .on("mouseout", () => {
                    tooltip.transition()
                        .duration(500)
                        .style("opacity", 0);
                });
                
                // Update positions on each tick
                simulation.on("tick", () => {
                    link
                        .attr("x1", d => d.source.x)
                        .attr("y1", d => d.source.y)
                        .attr("x2", d => d.target.x)
                        .attr("y2", d => d.target.y);
                    
                    node
                        .attr("transform", d => \`translate(\${d.x},\${d.y})\`);
                });
                
                // Drag functions
                function dragstarted(event, d) {
                    if (!event.active) simulation.alphaTarget(0.3).restart();
                    d.fx = d.x;
                    d.fy = d.y;
                }
                
                function dragged(event, d) {
                    d.fx = event.x;
                    d.fy = event.y;
                }
                
                function dragended(event, d) {
                    if (!event.active) simulation.alphaTarget(0);
                    d.fx = null;
                    d.fy = null;
                }
                
                // Control functions
                function resetZoom() {
                    svg.transition().duration(750).call(
                        zoom.transform,
                        d3.zoomIdentity
                    );
                }
                
                function centerGraph() {
                    const bounds = g.node().getBBox();
                    const fullWidth = width;
                    const fullHeight = height;
                    const widthScale = fullWidth / bounds.width;
                    const heightScale = fullHeight / bounds.height;
                    const scale = 0.8 * Math.min(widthScale, heightScale);
                    const translate = [
                        fullWidth / 2 - scale * (bounds.x + bounds.width / 2),
                        fullHeight / 2 - scale * (bounds.y + bounds.height / 2)
                    ];
                    
                    svg.transition().duration(750).call(
                        zoom.transform,
                        d3.zoomIdentity.translate(translate[0], translate[1]).scale(scale)
                    );
                }
                
                function toggleLabels() {
                    showLabels = !showLabels;
                    labels.style("display", showLabels ? "block" : "none");
                }
                
                // Handle window resize
                window.addEventListener('resize', () => {
                    const newWidth = window.innerWidth;
                    const newHeight = window.innerHeight;
                    svg.attr("width", newWidth).attr("height", newHeight);
                    simulation.force("center", d3.forceCenter(newWidth / 2, newHeight / 2));
                    simulation.alpha(0.3).restart();
                });
                
                // Initial center
                setTimeout(centerGraph, 1000);
            </script>
        </body>
        </html>`;
    }
}
exports.GraphWebviewProvider = GraphWebviewProvider;
//# sourceMappingURL=graphWebviewProvider.js.map