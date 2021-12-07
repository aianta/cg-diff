<template>
  <div id="app">
    <b-container fluid>
      <b-row>
        <b-col>
          <div class="d-flex flex-column">
            <!-- <img alt="Vue logo" src="./assets/logo.png"> -->
            <div class="d-flex">
              <h2>Graph 1</h2>
              <b-form-select v-model="graph1" :options="dataOptions"></b-form-select>
            </div>
            <div class="d-flex">
              <h2>Graph 2</h2>
              <b-form-select v-model="graph2" :options="dataOptions"></b-form-select>
            </div>
            
            <b-btn @click="churn()">compute</b-btn>
            <p>{{computeTime}}ms</p>
            <!-- <h1>gDiff</h1>
            <GraphRender :graph="gDiff" :width="300" :height="300"></GraphRender> -->
            <h1>hGraph</h1>
            <GraphRender :graph="hGraph"></GraphRender>
            <!-- <h1>Edge Decomposition</h1> -->
            <!-- <GraphRender v-for="(cluster,i) in clusters"
              :key="i"
              :graph="cluster"
              :width="300"
              :height="300"
              ></GraphRender>  -->
          </div>
        </b-col>
      </b-row>
    </b-container>


  </div>
</template>

<script>

import cg1 from '@/data/callgraph-simple-1.json'
import cg2 from '@/data/callgraph-simple-2.json'
import cg3 from '@/data/callgraph-read-file.json'
import cg4 from '@/data/test1.json'
import cg5 from '@/data/test2.json'
import cg6 from '@/data/callgraph-stream.json'
import cg7 from '@/data/callgraph-stream-string-builder.json'
import GraphRender from './components/GraphRender.vue';

function makeHGraph(g1,g2){
  function gDiff(g1, g2){

  //Stores gDiff's nodes
  let gDiffNodes = new Map();
  //Stores gDiff's edges
  let gDiffEdges = new Map();

  /* 
   * Load all the nodes from g1 into gDiff
   */
  for (let entry of g1.nodes){
      //console.log(entry)
      let node = {
        id: entry,
        /* 1 -> belongs to g1
         * 2 -> belongs to g2
         * 3 ->  belongs to both g1 & g2
         */
        owner: 1 
      }
      //console.log(node)
      gDiffNodes.set(entry, node)
  }

  /**
   * Read through all the nodes from g2 and mark their ownership
   */
  for (let entry of g2.nodes){
    //console.log(entry)
    //If gDiff already has an entry for this node, then the node must belong in both g1 & g2, so owner is set to 3.
    if (gDiffNodes.has(entry)){
      let node = gDiffNodes.get(entry)
      node.owner = 3 
    }else{
      // Otherwise the node belongs exclusively to g2.
      let node = {
        id: entry,
        owner: 2 
      }
      gDiffNodes.set(entry, node)
    }
  }

  /*
   * Load all edges from g1 into gDiff
   */
  //console.log('g1 edge count: ' + g1.links.length)
  for (let entry of g1.links){
    let edge = JSON.parse(JSON.stringify(entry));
    edge.owner = 1 //Label as owned by g1
    gDiffEdges.set(edgeId(entry), edge)
  }
  //console.log('gDiffEdges.size : ' + gDiffEdges.size)

  for(let entry of g2.links){
    // If either of the nodes belong only to g2, it is impossible for the edge to exist in both graphs.
    if (gDiffNodes.get(entry.source).owner == 2 || gDiffNodes.get(entry.target).owner == 2){
      let edge = JSON.parse(JSON.stringify(entry))
      edge.owner = 2 //Label as owned by g2
      gDiffEdges.set(edgeId(entry), edge)
    }

    /* If the two nodes are in both graphs, there are three possibilities. The first is that the edge is in g1 only, in which case we inserted the edge earlier.
     * The second case is that the edge is in both graphs. The algorithm checks the hashtable to see if the edge exists, and, if it does, the edge is labeled as belonging to 
     * both graphs. Otherwise, the edge is added and labled as only belonging to g2.
     */
    if(gDiffNodes.get(entry.source).owner == 3 && gDiffNodes.get(entry.target).owner == 3){
      
      if (gDiffEdges.has(edgeId(entry))){
        let edge = gDiffEdges.get(edgeId(entry))
        edge.owner = 3
      }else{
        let edge = JSON.parse(JSON.stringify(entry))
        edge.owner = 2
        gDiffEdges.set(edgeId(entry), edge)
      }
    }
  }

  //Assembles node & edge data together to allow traversals
  buildGraph(gDiffNodes, gDiffEdges)


  let result = {
    nodes: Array.from(gDiffNodes.values()),
    links: Array.from(gDiffEdges.values())
  }

  return [result, gDiffNodes, gDiffEdges];
}

function edgeId(edge){
  return edge.type+edge.source+edge.target
}

// eslint-disable-next-line no-unused-vars
function formatClusters(clusters){
  let result = []
  clusters.forEach(c=>{
    result.push(
      {
        nodes: Array.from(c.nodes.values()),
        links: Array.from(c.links.values())
      }
    )
  })

  return result
}

function findDuplicatedNodes(clusters){

  let resultSet = new Set()
  let seen = new Set()

  clusters.forEach(cluster=>{
    Array.from(cluster.nodes.values()).forEach(
      node=>seen.has(node.id)?resultSet.add(node.id):seen.add(node.id)
    )
  })

  //console.log('seen nodes:')
  // for (const e of resultSet){
  //   //console.log(e)
  // }

  return resultSet
}

// eslint-disable-next-line no-unused-vars
// function printClusterNodes(cluster){
//   console.log("cluster nodes:")
//   Array.from(cluster.nodes.values()).forEach(node=>console.log(node.id))
// }

// eslint-disable-next-line no-unused-vars
function decomposeByNodes(clusters, globalNodeMap){
  let result = []
  let duplicatedNodes = findDuplicatedNodes(clusters)

  //Make clusters for all duplicated nodes
  duplicatedNodes.forEach(nodeId=>{
    let node = globalNodeMap.get(nodeId)
    let cluster = {
      type: 'node',
      owner:node.owner,
      nodes: new Map(),
      links: new Map()
    }
    cluster.nodes.set(nodeId, node)
    result.push(cluster)
  })

  for (let cluster of clusters){

    //For every kind of node owner in a cluster
    let owners = clusterNodeOwners(cluster)
    owners.forEach(owner=>{
      let nodeClusters = computeNodeClusters(owner, cluster.nodes, duplicatedNodes)
      nodeClusters.forEach(cluster=>cluster.type = 'node')
      result.push(...nodeClusters)
    })

  }

  return result
}

function clusterNodeOwners(cluster){
  let result = new Set()
  Array.from(cluster.nodes.values()).forEach(node=>result.add(node.owner))
  return result
}

function decomposeByEdge(graph, nodeMap, edgeMap){
  let result = []
  const clusters1 = computeClusters(1, nodeMap, edgeMap)
  const clusters2 = computeClusters(2, nodeMap, edgeMap)
  const clusters3 = computeClusters(3, nodeMap, edgeMap)
  result.push(...clusters1,...clusters2,...clusters3)

  return result;

}

//Computes connected clusters of edges for a given owner label
// eslint-disable-next-line no-unused-vars
function computeNodeClusters(owner, nodeMap, excludeNodes){
  // eslint-disable-next-line no-unused-vars
  let result = []

  //Find a node with the matching owner label
  let n1 = Array.from(nodeMap.values()).find(n=>n.owner === owner && !excludeNodes.has(n.id))

  //If there is no such n1, we're done here
  if (n1 === undefined){
    return result
  }

  let toSearch = []
  toSearch.unshift(n1.id)

  //Perform a BFS to find the first cluster
  let cluster = bfsClusterNode(owner, toSearch, nodeMap, excludeNodes)
  result.push(cluster)

  /* Now go through the rest of the edges with the specified owner, and keep
   * starting BFS's and making clusters if we come across 
   * an edge that is not part of any cluster we've made
   * so far.
   */
  for (const [id, node] of nodeMap.entries()){
    if (node.owner === owner && !excludeNodes.has(node.id)){
       //console.log('looking for node: ' + id + " in existing clusters")
      //Find a cluster that already contains this node
      let containingCluster = result.find(cluster=>cluster.nodes.has(id))
      if (containingCluster === undefined){
        //console.log('Node not found! building cluster')
        //If we can't find such a cluster, it's time to a make a new cluster
        //containing this edge.
        result.push(bfsClusterNode(owner, [node.id], nodeMap, excludeNodes))
      }else{
        //console.log("Node found moving along!")
      }
    }
   
  }

  return result

}

//Computes connected clusters of edges for a given owner label
// eslint-disable-next-line no-unused-vars
function computeClusters(owner, nodeMap, edgeMap){
  // eslint-disable-next-line no-unused-vars
  let result = []

  //Find an edge with the matching owner label
  let e1 = Array.from(edgeMap.values()).find(e=>e.owner === owner)

  //If there is no such e1, we're done here
  if (e1 === undefined){
    return result
  }

  let toSearch = []
  toSearch.unshift(e1.source)
  toSearch.unshift(e1.target)

  //Perform a BFS to find the first cluster
  let cluster = bfsCluster(owner, toSearch, nodeMap)
  result.push(cluster)

  /* Now go through the rest of the edges with the specified owner, and keep
   * starting BFS's and making clusters if we come across 
   * an edge that is not part of any cluster we've made
   * so far.
   */
  for (const [id, edge] of edgeMap.entries()){
    if (edge.owner === owner){
       //console.log('looking for edge: ' + id + " in existing clusters")
      //Find a cluster that already contains this edge
      let containingCluster = result.find(cluster=>cluster.links.has(id))
      if (containingCluster === undefined){
        //console.log('Edge not found! building cluster')
        //If we can't find such a cluster, it's time to a make a new cluster
        //containing this edge.
        result.push(bfsCluster(owner, [edge.target,edge.source], nodeMap))
      }else{
        //console.log("Edge found moving along!")
      }
    }
   
  }

  return result

}

//Bredth-first search on nodes in toSearch only using edges labeled with matching owner.
//Optionally excludes given nodes from the search, including edges leading into or coming out
//of them.
function bfsClusterNode(owner, toSearch, nodeMap, excludeNodes=new Set()){
  //console.log("building clusters for owner " + owner)
  //console.log(toSearch)
  let cluster = {
    type: 'edge',
    owner: owner,
    nodes: new Map(),
    links: new Map()
  }

  //Breadth-frist search 
  while(toSearch.length > 0){
    //console.log(toSearch)
    let currNode = toSearch.pop() //Pop's the label off toSearch
    //console.log("toSearch popped value: " + currNode)
    currNode = nodeMap.get(currNode) //Resolves the underlying node
    //Add the current node to the cluster
    cluster.nodes.set(currNode.id, JSON.parse(JSON.stringify(currNode)))

    let currNeighbors = []
    for (let neighbourId of currNode.neighbors){
      let neighbor = nodeMap.get(neighbourId)
      if (neighbor !== undefined){
        currNeighbors.push(neighbor)
      }

    }

    let nodesWithSameOwner = currNeighbors.filter(node => node.owner === owner)
    nodesWithSameOwner
      //filter out edges that have an excluded node as either target or source
      .filter(n=>!excludeNodes.has(n))
      .forEach(n=>{

      //And add their targets to the search list if they aren't already in the cluster.
      //(we haven't seen them before) and they aren't already in the search list.
      if (!cluster.nodes.has(n.id) && !toSearch.includes(n.id)){

        toSearch.unshift(n.id)
      }

    })
  }

  //console.log("Built cluster!")
  //console.log(cluster)

  return cluster
}

//Bredth-first search on nodes in toSearch only using edges labeled with matching owner.
//Optionally excludes given nodes from the search, including edges leading into or coming out
//of them.
function bfsCluster(owner, toSearch, nodeMap, excludeNodes=new Set()){
  //console.log("building clusters for owner " + owner)
  //console.log(toSearch)
  let cluster = {
    type: 'edge',
    owner: owner,
    nodes: new Map(),
    links: new Map()
  }

  //Breadth-frist search 
  while(toSearch.length > 0){
    //console.log(toSearch)
    let currNode = toSearch.pop() //Pop's the label off toSearch
    //console.log("toSearch popped value: " + currNode)
    currNode = nodeMap.get(currNode) //Resolves the underlying node
    //Add the current node to the cluster
    cluster.nodes.set(currNode.id, JSON.parse(JSON.stringify(currNode)))

    let edgesWithSameOwner = currNode.edges.filter(edge => edge.owner === owner)
    edgesWithSameOwner
      //filter out edges that have an excluded node as either target or source
      .filter(e=>!excludeNodes.has(e.target) && !excludeNodes.has(e.source))
      .forEach(e=>{

      //Add all out edges with the same owner to the cluster
      cluster.links.set(edgeId(e), JSON.parse(JSON.stringify(e)))
      //And add their targets to the search list if they aren't already in the cluster.
      //(we haven't seen them before) and they aren't already in the search list.
      if (!cluster.nodes.has(e.target) && !toSearch.includes(e.target)){
        toSearch.unshift(e.target)
      }

      if (!cluster.nodes.has(e.source) && !toSearch.includes(e.source)){
        toSearch.unshift(e.source)
      }

    })
  }

  //console.log("Built cluster!")
  //console.log(cluster)

  return cluster
}

function clustersToNodeMap(clusters){
  let result = new Map()

  for(let cluster of clusters){

    //If the cluster node size is 1
    if (cluster.nodes.size === 1){
      //Then this is just a normal node.
      let node = Array.from(cluster.nodes.values())[0]
      result.set(node.id, node)
    }else{

        //Otherwise we have a metanode on our hands.
        let innerNodes = []
        let innerNodeIds = []
        let metaNodeId = "{"
        let metaOwner = -1
        for (let innerNode of Array.from(cluster.nodes.values())){
          metaOwner = innerNode.owner
          metaNodeId += innerNode.id + ","
          innerNodes.push(innerNode)
          innerNodeIds.push(innerNode.id)
        }
        metaNodeId = metaNodeId.substring(0,metaNodeId.length-1)
        metaNodeId += "}"

        let metaNode = {
          id: metaNodeId,
          owner: metaOwner,
          innerNodes: innerNodes,
          innerNodeIds: innerNodeIds
        }

        result.set(metaNodeId, metaNode)
    }
  }

  return result
}

function nodeMapToEdgeMap(nodeMap,edgeMap){
  let result = new Map();

  for (const edge of edgeMap.values()){
    let sourceNode = nodeMap.get(edge.source)
    let targetNode = nodeMap.get(edge.target)

    if (sourceNode === undefined){
      sourceNode = findMetaNode(edge.source, nodeMap)
    }

    if(targetNode === undefined){
      targetNode = findMetaNode(edge.target, nodeMap)
    }

    let newEdge ={
      source: sourceNode.id,
      target: targetNode.id,
      type: edge.type
    }

    if (newEdge.source === newEdge.target){
      continue // Don't capture edges inside metanodes anymore
    }

    result.set(edgeId(newEdge), newEdge)

  }

  return result
}

function findMetaNode(innerNodeId, nodeMap){
  return Array.from(nodeMap.values())
  //Find the metanodes in the node map
  .filter(node=>node.innerNodes !== undefined)
  .find(metaNode => metaNode.innerNodeIds.includes(innerNodeId))
}


//Assembles node & edge data together to allow traversals
function buildGraph(nodeMap, edgeMap){
  
    //let incommingLinks = new Map();

    // Link graph up
    Array.from(edgeMap.values()).forEach( edge=>{
      //Count incoming edges
      //incommingLinks.set(edge.target, (incommingLinks.get(edge.target) !== undefined? incommingLinks.get(edge.target):0) + 1)

      const a = nodeMap.get(edge.source)
      const b = nodeMap.get(edge.target)

      a.neighbors = a.neighbors || []
      b.neighbors = b.neighbors || []

      !a.neighbors && (a.neighbors = [])
      !b.neighbors && (b.neighbors = [])
      a.neighbors.push(b.id)
      b.neighbors.push(a.id)

      !a.edges && (a.edges = [])
      !b.edges && (b.edges = [])
      a.edges.push(edge)
      b.edges.push(edge)

      !a.inEdges && (a.inEdges = [])
      !b.inEdges && (b.inEdges = [])

      !a.outEdges && (a.outEdges = [])
      !b.outEdges && (b.outEdges = [])

   
      a.outEdges.push(edge)
      b.inEdges.push(edge)

      

      }
    

    );
  

  }


  const [graph,nodeMap,edgeMap] = gDiff(g1,g2)

  let rawClusters =  decomposeByEdge(graph,nodeMap,edgeMap)

  let nodeClusters = decomposeByNodes(rawClusters, nodeMap)

  let hGraphNodeMap = clustersToNodeMap(nodeClusters)
  let hGraphEdgeMap = nodeMapToEdgeMap(hGraphNodeMap,edgeMap)

  let hGraph = {
    nodes: Array.from(hGraphNodeMap.values()),
    links: Array.from(hGraphEdgeMap.values())
  }

  return hGraph
}




export default {
  name: 'App',
  components: { GraphRender },
  data(){
    return {
      dataOptions: [
        {
        value: cg1,
        text: 'hello world'
      },{
        value:cg2,
        text: 'hello world with system property'
      },
      {
        value: cg3,
        text: 'hello world with read file'
      },
      {
        value: cg6,
        text: 'hello world with stream'
      },
      {
        value: cg7,
        text: 'hello world with stream and string builder'
      },
      {
        value: cg4,
        text: 'test-1'
      },
      {
        value: cg5,
        text: 'test-2'
      }
    
      ],
      graph1: undefined,
      graph2: undefined,
      gDiff: undefined,
      clusters: [],
      nodeClusters: [],
      hGraph: {
        nodes:[],
        links:[]
      },
      computeTime: 0
    }
  },
  mounted(){
    
  },
  methods:{
    churn(){
  
      console.log("Computing graph difference")

      let instance = this
      let start = Date.now()
      this.$worker.run(
        makeHGraph,
        [this.$data.graph1,this.$data.graph2]
      ).then(result=>{
        instance.hGraph = result
        instance.computeTime = Date.now() - start
      })
      .catch(err=>{
          console.log("Oh no! An error occurred computing graph differences.")
          console.log(err)
        })

    }
  }

}
</script>

<style>
#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  margin-top: 60px;
}
</style>
