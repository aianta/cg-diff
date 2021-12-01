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
                .linkAutoColorBy('owner')
                .nodeThreeObject(node => {
                    const sprite = new SpriteText(node.id)
                    sprite.material.depthWrite = false;
                    sprite.color = node.color;
                    sprite.textHeight = 8;
                    return sprite
                })

        }
    }
}
</script>

<style>

</style>