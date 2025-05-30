import * as vscode from 'vscode';
import { DependencyGraph } from './dependencyAnalyzer';

export class GraphWebviewProvider {
    constructor(private readonly extensionUri: vscode.Uri) {}

    public getHtmlForWebview(webview: vscode.Webview, dependencies: DependencyGraph): string {
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
                <div style="margin-top: 10px;">
                    <label for="depthLevel">Depth Level: </label>
                    <select id="depthLevel" onchange="changeDepth()" style="background: var(--vscode-dropdown-background); color: var(--vscode-dropdown-foreground); border: 1px solid var(--vscode-dropdown-border);">
                        ${Array.from({length: 10}, (_, i) => i + 1).map(i =>
                            `<option value="${i}" ${i === dependencies.maxDepth ? 'selected' : ''}>${i}</option>`
                        ).join('')}
                    </select>
                </div>
            </div>
            <div id="info">
                <h3>Dependency Graph</h3>
                <p>Entry Point: <strong>${dependencies.entryPoint}</strong></p>
                <p>Depth Level: <strong>${dependencies.maxDepth}</strong></p>
                <p>Total Files: <strong>${dependencies.nodes.length}</strong></p>
                <p>Total Dependencies: <strong>${dependencies.edges.length}</strong></p>
            </div>
            <div class="tooltip"></div>

            <script src="${d3Uri}"></script>
            <script>
                // Wait for DOM to be ready
                document.addEventListener('DOMContentLoaded', function() {
                    initializeGraph();
                });

                // Also try to initialize immediately in case DOM is already ready
                if (document.readyState === 'loading') {
                    document.addEventListener('DOMContentLoaded', initializeGraph);
                } else {
                    initializeGraph();
                }

                function initializeGraph() {
                    // Check if D3 loaded successfully
                    if (typeof d3 === 'undefined') {
                        console.error('D3.js failed to load');
                        document.getElementById('graph').innerHTML = '<text x="50%" y="50%" text-anchor="middle" style="font-size: 20px; fill: var(--vscode-editor-foreground);">Error: D3.js library failed to load</text>';
                        return;
                    }

                    const data = ${JSON.stringify(dependencies)};
                    let showLabels = true;

                    // Check if we have any nodes
                    if (!data.nodes || data.nodes.length === 0) {
                        const svg = d3.select("#graph");
                        svg.append("text")
                            .attr("x", "50%")
                            .attr("y", "50%")
                            .attr("text-anchor", "middle")
                            .style("font-size", "20px")
                            .style("fill", "var(--vscode-editor-foreground)")
                            .text("No dependencies found");
                        return;
                    }

                    // Set up the SVG
                    const width = window.innerWidth;
                    const height = window.innerHeight;

                    const svg = d3.select("#graph")
                        .attr("width", width)
                        .attr("height", height);

                    // Clear any existing content
                    svg.selectAll("*").remove();

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

                    // Initialize node positions to prevent NaN issues
                    data.nodes.forEach((node, i) => {
                        node.x = width / 2 + (Math.random() - 0.5) * 100;
                        node.y = height / 2 + (Math.random() - 0.5) * 100;
                    });

                    // Create a hierarchical layout instead of force simulation
                    const levels = new Map();
                    const visited = new Set();

                    // Calculate levels using BFS from entry point
                    function calculateLevels() {
                        const queue = [{ id: data.entryPoint, level: 0 }];
                        levels.set(data.entryPoint, 0);
                        visited.add(data.entryPoint);

                        while (queue.length > 0) {
                            const { id, level } = queue.shift();

                            // Find all nodes that this node points to
                            data.edges.forEach(edge => {
                                if (edge.source === id && !visited.has(edge.target)) {
                                    levels.set(edge.target, level + 1);
                                    visited.add(edge.target);
                                    queue.push({ id: edge.target, level: level + 1 });
                                }
                            });
                        }
                    }

                    calculateLevels();

                    // Group nodes by level
                    const nodesByLevel = new Map();
                    data.nodes.forEach(node => {
                        const level = levels.get(node.id) || 0;
                        if (!nodesByLevel.has(level)) {
                            nodesByLevel.set(level, []);
                        }
                        nodesByLevel.get(level).push(node);
                    });

                    // Position nodes in a left-to-right hierarchy
                    const levelWidth = 200;
                    const nodeHeight = 60;

                    nodesByLevel.forEach((nodesAtLevel, level) => {
                        const x = 100 + level * levelWidth;
                        const startY = (height - (nodesAtLevel.length - 1) * nodeHeight) / 2;

                        nodesAtLevel.forEach((node, index) => {
                            node.x = x;
                            node.y = startY + index * nodeHeight;
                            node.fx = x; // Fix x position
                            node.fy = startY + index * nodeHeight; // Fix y position
                        });
                    });

                    // Create force simulation with minimal forces for stable positioning
                    const simulation = d3.forceSimulation(data.nodes)
                        .force("link", d3.forceLink(data.edges).id(d => d.id).distance(150).strength(0.1))
                        .force("charge", d3.forceManyBody().strength(-50))
                        .force("collision", d3.forceCollide().radius(25))
                        .alpha(0.3)
                        .alphaDecay(0.1);

                    // Create links
                    const link = g.append("g")
                        .selectAll("line")
                        .data(data.edges)
                        .enter().append("line")
                        .attr("class", "link")
                        .style("stroke", "var(--vscode-editor-foreground)")
                        .style("stroke-opacity", 0.6)
                        .style("stroke-width", 1);

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
                        .style("cursor", "pointer")
                        .call(d3.drag()
                            .on("start", dragstarted)
                            .on("drag", dragged)
                            .on("end", dragended));

                    // Add circles to nodes
                    node.append("circle")
                        .attr("r", d => d.id === data.entryPoint ? 15 : 10)
                        .style("fill", d => {
                            switch(d.type) {
                                case 'python': return '#3776ab';
                                case 'javascript': return '#f7df1e';
                                case 'typescript': return '#3178c6';
                                default: return '#666';
                            }
                        })
                        .style("stroke", "var(--vscode-editor-foreground)")
                        .style("stroke-width", d => d.id === data.entryPoint ? 4 : 2);

                    // Add labels to nodes
                    const labels = node.append("text")
                        .text(d => d.label)
                        .attr("x", 15)
                        .attr("y", 5)
                        .style("font-size", "12px")
                        .style("fill", "var(--vscode-editor-foreground)")
                        .style("pointer-events", "none");

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

                    // Drag functions - allow vertical movement but maintain horizontal levels
                    function dragstarted(event, d) {
                        if (!event.active) simulation.alphaTarget(0.1).restart();
                        d.fy = d.y; // Only fix y position, allow x to maintain level
                    }

                    function dragged(event, d) {
                        d.fy = event.y; // Allow vertical dragging only
                    }

                    function dragended(event, d) {
                        if (!event.active) simulation.alphaTarget(0);
                        d.fy = null; // Release y constraint
                    }

                    // Control functions
                    window.resetZoom = function() {
                        svg.transition().duration(750).call(
                            zoom.transform,
                            d3.zoomIdentity
                        );
                    };

                    window.centerGraph = function() {
                        try {
                            const bounds = g.node().getBBox();
                            const fullWidth = width;
                            const fullHeight = height;
                            const padding = 50;

                            const availableWidth = fullWidth - 2 * padding;
                            const availableHeight = fullHeight - 2 * padding;

                            const widthScale = availableWidth / bounds.width;
                            const heightScale = availableHeight / bounds.height;
                            const scale = Math.min(widthScale, heightScale, 1); // Don't scale up

                            const centerX = fullWidth / 2;
                            const centerY = fullHeight / 2;
                            const boundsX = bounds.x + bounds.width / 2;
                            const boundsY = bounds.y + bounds.height / 2;

                            const translate = [
                                centerX - scale * boundsX,
                                centerY - scale * boundsY
                            ];

                            svg.transition().duration(750).call(
                                zoom.transform,
                                d3.zoomIdentity.translate(translate[0], translate[1]).scale(scale)
                            );
                        } catch (error) {
                            // Fallback to simple center
                            svg.transition().duration(750).call(
                                zoom.transform,
                                d3.zoomIdentity
                            );
                        }
                    };

                    window.toggleLabels = function() {
                        showLabels = !showLabels;
                        labels.style("display", showLabels ? "block" : "none");
                    };

                    window.changeDepth = function() {
                        const select = document.getElementById('depthLevel');
                        const newDepth = parseInt(select.value);

                        // Send message to extension to re-analyze with new depth
                        const vscode = acquireVsCodeApi();
                        vscode.postMessage({
                            command: 'changeDepth',
                            depth: newDepth
                        });
                    };

                    // Handle window resize
                    window.addEventListener('resize', () => {
                        const newWidth = window.innerWidth;
                        const newHeight = window.innerHeight;
                        svg.attr("width", newWidth).attr("height", newHeight);
                        simulation.force("center", d3.forceCenter(newWidth / 2, newHeight / 2));
                        simulation.alpha(0.3).restart();
                    });

                    // Initial center after a short delay
                    setTimeout(() => {
                        if (typeof window.centerGraph === 'function') {
                            window.centerGraph();
                        }
                    }, 1000);
                }
            </script>
        </body>
        </html>`;
    }
}
