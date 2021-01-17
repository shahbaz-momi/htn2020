import React from "react";

import {Gitgraph} from "@gitgraph/react";
import {Typography} from "@material-ui/core";
import Button from "@material-ui/core/Button";

import Branch from "./Branch";

class GitGraph extends React.Component {

    render() {
        let project = this.props.project;

        if (project == null) {
            return (
                <Typography>
                    No Project Selected
                </Typography>
            );
        }

        if(project.commits == null || project.commits.length === 0) {
            return (
                <Typography>
                    No commits
                </Typography>
            );
        }

        return (
            <div>
                <Gitgraph key={this.props.invalidateKey} selectedCommit={this.props.selectedCommit}>
                    {(graph) => {
                        this.createGraph(graph, project)
                    }}
                </Gitgraph>
            </div>
        );
    }


    static getBranches(project) {
        let branches = [];

        if (project.commits === undefined)
            return branches;

        project.commits.forEach((it) => {
            if (it === undefined || it === null) return;

            if (it.branchingName !== null && it.branchingName !== undefined) {
                branches.push(it.branchingName);
            }
        });

        return branches;
    }

    static handleUse = (commit) => {
        Branch.currentCommit = commit;
        if (Branch.listener) Branch.listener();
    };

    produceBody(project, commit) {
        return (
            <div>
                <Button style={{"marginLeft": "4px", "marginRight": "4px"}} variant="outlined" onClick={() => {
                    GitGraph.handleUse(commit)
                }}>
                    Use
                </Button>

                {
                    project && commit && commit.comments && commit.comments.length > 0 &&
                    <Button style={{"marginLeft": "4px", "marginRight": "4px"}} variant="outlined" onClick={()=>{Branch.commentListener(commit)}}>
                        Annotations ({commit.comments.length})
                    </Button>
                }
                <Button style={{"marginLeft": "4px", "marginRight": "4px"}}
                        href={"http://192.168.137.1:8080/" + project.id + "/" + commit.id + "/" + commit.files[0]}
                        variant="outlined">
                    DOWNLOAD
                </Button>
            </div>
        )
    }

    createGraph(graph, project) {
        // create graph on the master branch
        let masterTop = project.commits.find((it) => {
            return it.branchingName === "master"
        });
        if (masterTop === undefined)
            return;
        let master = graph.branch("master");

        let selected = this.props.selectedCommit;


        var tag = null;
        if(selected !== null && selected.id === masterTop.id) {
            tag = "SELECTED"
        }

        master.commit({
            subject: masterTop.message,
            author: masterTop.author,
            hash: masterTop.id,
            tag: tag,
            body: this.produceBody(project, masterTop)
        });

        this.createGraph0(graph, master, masterTop, project.commits, project)
    }

    createGraph0(graph, branch, top, commits, project) {
        if (top === undefined)
            return;

        // get all with this as the top commit
        let sub = commits.filter((it) => {
            return it !== undefined && it.parentId === top.id
        });

        if (sub.length > 0) {
            // create all these commits here now with the branches, then recurse
            let branches = sub.filter((it) => {
                return it !== undefined && it.branchingName !== null
            });
            let direct = sub.find((it) => {
                return it !== undefined && it.branchingName === null
            });


            // commit the rest of the branches from here now
            if (branches !== undefined && branches.length > 0) {
                branches.forEach((b) => {
                    console.log("Branching: " + b.message);
                    let bobj = graph.branch(b.branchingName);

                    let selected = this.props.selectedCommit;

                    var tag = null;
                    if(selected !== null && selected.id === b.id) {
                        tag = "SELECTED"
                    }

                    bobj.commit({
                        subject: b.message,
                        author: b.author,
                        hash: b.id,
                        tag: tag,
                        body: this.produceBody(project, b)
                    });
                    this.createGraph0(graph, bobj, b, commits, project)
                })
            }

            if (direct !== undefined) {
                console.log("Doing commit: " + direct.message);
                console.log("Branch: " + branch);

                let selected = this.props.selectedCommit;

                var tag = null;
                if(selected !== null && selected.id === direct.id) {
                    tag = "SELECTED"
                }

                branch.commit({
                    subject: direct.message,
                    author: direct.author,
                    hash: direct.id,
                    tag: tag,
                    body: this.produceBody(project, direct)
                });
            }

            // begin recursion
            if (direct !== undefined) {
                console.log("Continuing commit: " + direct.message);
                this.createGraph0(graph, branch, direct, commits, project)
            }
        }
    }
}

export default GitGraph;
