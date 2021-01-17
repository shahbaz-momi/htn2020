import React, {Component} from 'react';
import './App.css';
import {withStyles} from '@material-ui/core/styles';
import Paper from '@material-ui/core/Paper';
import axios from 'axios';

import Branch from "./Branch";
import { Refresh } from "@material-ui/icons";

import {
    AppBar,
    Button,
    Checkbox,
    CircularProgress,
    Container,
    CssBaseline,
    FormControlLabel,
    TextField,
    Toolbar,
    Typography
} from '@material-ui/core';

import GitGraph from "./GitGraph";
import ProjectsDialog from "./ProjectsDialog";
import AnnotateView from "./AnnotateView";

const styles = theme => ({
    root: {
        display: 'flex',
        height: '100vh'
    },
    grow: {
        flexGrow: 1
    },
    line: {
        flexGrow: 1,
        display: 'flex',
        flexDirection: 'row',
        alignItems: "baseline",
        marginTop: theme.spacing(0.75),
        marginBottom: theme.spacing(0.75)
    },
    line_center: {
        flexGrow: 1,
        display: 'flex',
        flexDirection: 'row',
        alignItems: "center",
        marginTop: theme.spacing(0.75),
        marginBottom: theme.spacing(0.75)
    },
    toolbar: {
        paddingRight: 24
    },
    toolbarIcon: {
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'flex-end',
        padding: '0 8px',
        ...theme.mixins.toolbar
    },
    appBarSpacer: theme.mixins.toolbar,
    paper: {
        marginTop: theme.spacing(2),
        marginBottom: theme.spacing(2),
        padding: theme.spacing(2),
        display: 'flex',
        overflow: 'auto',
        flexDirection: 'column',
    },
    content: {
        flexGrow: 1,
        overflow: 'auto'
    },
    spacedButtonRight: {
        marginRight: '12px'
    },
    leftRightMargin: {
        marginLeft: '12px',
        marginRight: '12px'
    },
    container: {
        paddingTop: theme.spacing(4),
        paddingBottom: theme.spacing(4),
    },
});

class App extends Component {

    constructor(props) {
        super(props);

        this.state = {
            showAnnotateview: false,
            branching: false,
            projects: [],
            project: null,
            showProjectsDialog: false,
            isUploadAllowed: false,
            selectedFile: null,
            isUploading: false,
            uploadStatus: null,
            commitMessage: null,
            branchName: null,
            commit: null,
            commentCommit: null,
            author: null,
            invalidateKey: 0,
        };

        Branch.listener = this.onCommitChanged;
        Branch.commentListener = this.onCommentClicked;
    }

    onCommitChanged = () => {
        this.setState({
            commit: Branch.currentCommit,
            invalidateKey: this.state.invalidateKey + 1
        })
    };

    onCommentClicked = (commentCommit) => {
        this.setState({
            showAnnotateView: true,
            commentCommit: commentCommit
        })
    };

    async loadData() {
        axios.get("http://192.168.137.1:8080/project/get_all", {
            headers: {
                "Access-Control-Allow-Origin": "http://192.168.137.1:8080",
                "Access-Control-Allow-Methods": "GET, POST",
                "Access-Control-Allow-Headers": "Origin, Accept, Content-Type, Authorization"
            }
        })
            .then((resp) => {
                console.log(resp);
                let data = resp.data;

                let index = 0;
                // reuse our index
                if(this.state.project !== null) {
                    for(let i = 0; i < data.length; i ++) {
                        if(data[i].id === this.state.project.id) {
                            index = i;
                            break;
                        }
                    }
                }

                this.setState(
                    {
                        projects: data,
                        project: data[index],
                        invalidateKey: this.state.invalidateKey + 1
                    }
                );
            }).catch((error) => {
                console.log(error);
            }
        )
    }

    toggleDialog = () => {
        const current = this.state;
        this.setState({
            showProjectsDialog: !current.showProjectsDialog
        });
    };

    fileSelected = ({target}) => {
        // this.doUpload(target.files[0])
        this.setState({
            isUploadAllowed: true,
            selectedFile: target.files[0]
        })
    };

    async handleNewProject(projectName) {
        axios.get("http://192.168.137.1:8080/project/init",  {
            params: {
                name: projectName,
            },

            headers: {
                "Access-Control-Allow-Origin": "http://192.168.137.1:8080",
                "Access-Control-Allow-Methods": "GET, POST",
                "Access-Control-Allow-Headers": "Origin, Accept, Content-Type, Authorization"
            }
        }).finally( () => {
                window.location.reload()
            }
        )
    }

    async handleCommitRequest() {
        let message = this.state.commitMessage;

        let isBranching = this.state.branching;
        var branching = null;

        let parent = this.state.commit;

        if(isBranching) branching = this.state.branchName;


        var parentId = null;

        if(parent === null) {
            parentId = "INIT";
            branching = "master";
        } else {
            parentId = parent.id;
        }

        axios.get("http://192.168.137.1:8080/project/" + this.state.project.id + "/commit",  {
            params: {
                message: message,
                branching: branching,
                parent: parentId,
                author: this.state.author,
            },

            headers: {
                "Access-Control-Allow-Origin": "http://192.168.137.1:8080",
                "Access-Control-Allow-Methods": "GET, POST",
                "Access-Control-Allow-Headers": "Origin, Accept, Content-Type, Authorization"
            }
        }).then((resp) => {
            let commit = resp.data;
            this.doUpload(this.state.selectedFile, commit)
                .then(() => {
                    window.location.reload()
                })
        }).catch((error) => {
            console.log(error)
        })
    };

    async doUpload(file, commit) {
        const formData = new FormData();

        formData.append("file", file);
        formData.append("relative_path", file.name);

        this.setState({
            isUploading: true,
            isUploadAllowed: false
        });

        let project = this.state.project;

        axios.post("http://192.168.137.1:8080/project/" + project.id + "/upload/" + commit.id, formData, {
            headers: {
                "Access-Control-Allow-Origin": "http://192.168.137.1:8080",
                "Access-Control-Allow-Methods": "GET, POST",
                "Access-Control-Allow-Headers": "Origin, Accept, Content-Type, Authorization"
            }
        })
            .then((resp) => {
                let data = resp.data;

                if(data.success) {
                    this.setState({
                        uploadStatus: "Success"
                    });
                } else {
                    this.setState({
                        uploadStatus: "Failed. Please try again."
                    });
                }
            }).catch((error) => {
                this.setState({
                    uploadStatus: "Failed. Please try again."
                });
        }).then(() => {
            this.setState({
                isUploading: false
            });
        });
    };

    componentWillMount() {
        this.loadData()
    }

    render() {
        const {classes} = this.props;

        return (
            <div className={classes.root}>
                <CssBaseline/>
                <AppBar position="absolute">
                    <Toolbar className={classes.toolbar}>
                        <Typography component="h1" variant="h6" noWrap className={classes.grow}>
                            Git 3D
                        </Typography>
                    </Toolbar>
                </AppBar>
                <main className={classes.content}>
                    <div className={classes.appBarSpacer}/>
                    <Container maxWidth="xl" className={classes.container}>
                        <div className={classes.line_center}>
                            <Typography variant="h5" className={classes.grow}>
                                Project
                            </Typography>
                            <Button onClick={() => { this.loadData() }} variant="outlined" color="secondary">
                                <Refresh/>
                            </Button>
                        </div>
                        <Paper className={classes.paper}>
                            <div className={classes.line}>
                                <Typography className={classes.grow}>
                                    {
                                        (this.state.project === null || this.state.project === undefined) ? "None Selected" : this.state.project.name
                                    }
                                </Typography>
                                <Button variant="outlined" color="secondary" onClick={this.toggleDialog}>
                                    CHANGE
                                </Button>
                            </div>
                            <div className={classes.line}>
                                <TextField className={classes.grow} variant="standard" label="Author" value={this.state.author} onChange={ (e) => { this.setState({author: e.target.value})}} />
                            </div>
                            <div className={classes.line_center}>
                                <input id="file-input" accept="*/*" type="file" onChange={this.fileSelected}/>
                                <div className={classes.grow}/>
                                <Typography className={classes.leftRightMargin}>
                                    {
                                        (this.state.uploadStatus == null)? "" : this.state.uploadStatus
                                    }
                                </Typography>
                                {
                                    this.state.isUploading && <CircularProgress className={classes.leftRightMargin}/>
                                }
                            </div>
                            <div className={classes.line}>
                                <Button onClick={() => { this.handleCommitRequest() }} className={classes.spacedButtonRight} variant="outlined" color="secondary" disabled={!this.state.isUploadAllowed || this.state.commitMessage === null || this.state.commitMessage === "" || this.state.commitMessage === undefined || this.state.project === null || (this.state.commit === null && this.state.project.commits.length > 0) }>
                                    COMMIT
                                </Button>
                                <TextField variant="standard" label="Commit message" onChange={ (e) => {this.setState({ commitMessage: e.target.value })}} className={classes.grow}/>
                            </div>
                            <div className={classes.line}>
                                <FormControlLabel control={
                                    <Checkbox/>
                                } label="New branch" onChange={(event, checked) => {
                                    this.setState(
                                        {
                                            branching: checked
                                        }
                                    )
                                }}/>
                                <TextField id="branch_field" variant="standard" label="Branch name" onChange={(e) => {this.setState( { branchName: e.target.value } )}}
                                           className={classes.grow} disabled={!this.state.branching}/>
                            </div>
                        </Paper>
                        <Typography variant="h5">
                            History
                        </Typography>
                        <Paper className={classes.paper}>
                            <GitGraph invalidateKey={this.state.invalidateKey} project={this.state.project} selectedCommit={this.state.commit} onUse={(commit) => { alert(commit.id) }}/>
                        </Paper>
                    </Container>
                    <ProjectsDialog open={this.state.showProjectsDialog} onNewProject={(project) => {this.handleNewProject(project)}} onClose={() => {
                        this.setState({
                            showProjectsDialog: false
                        })

                    }} projects={this.state.projects} onSelected={(project) => {
                        this.setState(
                            {
                                project: project,
                                isUploadAllowed: false,
                                selectedFile: null,
                                isUploading: false,
                                uploadStatus: null,
                                commitMessage: null,
                                branchName: null,
                                commit: null,
                                branching: false,
                                invalidateKey: this.state.invalidateKey + 1
                            }
                        );
                    }}/>



                    <AnnotateView open={this.state.showAnnotateView} onClose={() => {
                        this.setState({
                            showAnnotateView: false
                        })
                    }} commit={this.state.commentCommit}/>

                </main>
            </div>
        );
    }
}

export default withStyles(styles)(App);
