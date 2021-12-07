<template>
    <div class="canvas">
        <div ref="root"></div>
    </div>
    
</template>
<script>

// import * as THREE from 'three'
import ForceGraph3D from '3d-force-graph'
import SpriteText from 'three-spritetext'
// import * as d3 from 'd3-force-3d'

// const graph = ForceGraph3D({
//     rendererConfig:{
//         antialias: false,
//         alpha: false,
//         stencil: false,
//         powerPreference: "high-performance",
//         preserveDrawingBuffer: false
//     }
// })

export default {
    name: 'GraphRender',
    props: ['graph', 'width','height'],
    data(){
        return{
            render: undefined,
            internalData: undefined
        }
    },
    mounted(){
        if(this.graph){
            
            this.initGraph()
        }
    },
    watch: {
        graph: function(){
            this.initGraph();
        }
    },
    methods: {
        zoomToNode(node){
             const distance = 250
            const distRatio = 1 + distance/Math.hypot(node.x, node.y, node.z);

            this.render.cameraPosition(
                { x: node.x * distRatio, y: node.y * distRatio, z: node.z * distRatio }, // new position
                node, // lookAt ({ x, y, z })
                3000  // ms transition duration
            )
        },
        initGraph(){
            console.log(this.$refs.root)

    this.render = ForceGraph3D({
        rendererConfig:{
        antialias: false,
        alpha: false,
        stencil: false,
        powerPreference: "high-performance",
        preserveDrawingBuffer: false
    }
    })(this.$refs.root)
                .height(this.height?this.height:this.$refs.root.clientHeight)
                .width(this.width?this.width:this.$refs.root.clientWidth)
                .graphData(this.graph)
                .nodeAutoColorBy('owner')
                .linkLabel(link=>link.type)
                .linkWidth(2)
                .linkAutoColorBy('owner')
                
                .nodeThreeObject(node => {
       
                    const sprite = new SpriteText(node.id.length > 300?"<META_NODE>":node.id)
                    sprite.material.depthWrite = false;
                    sprite.color = node.color;
                    sprite.textHeight = 10;
                    return sprite
                })
               
                this.render.numDimensions(2)
                this.render.d3Force('charge').strength(-(Math.min(15*(this.graph.nodes.length + this.graph.links.length),100000)))
                

                const distance = 1000
                //const distRatio = 1 + distance/Math.hypot(0, 0, 0);

                this.render.cameraPosition(
                    {x: 0, y: 0, z: distance},
                    {x:0,y:0,z:0},
                    1000
                )
        }
    }
}
</script>

<style>

</style>