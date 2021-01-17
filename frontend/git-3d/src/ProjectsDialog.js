import React from "react";
import {Dialog, DialogActions, DialogTitle, ListItemText, TextField} from "@material-ui/core";
import Button from "@material-ui/core/Button";
import List from "@material-ui/core/List";
import ListItem from "@material-ui/core/ListItem";
import AddIcon from '@material-ui/icons/Add';

class ProjectsDialog extends React.Component {

    constructor(props) {
        super(props);

        this.state = {
            projectName: null
        };
    }

    componentWillMount() {
        this.setState(
            {
                projectName: null
            }
        )
    }

    onClose = () => {
        this.props.onClose()
    };

    render() {
        return (
        <Dialog onClose={this.onClose} open={this.props.open}>
            <DialogTitle>Select Project</DialogTitle>
                <List>
                    {
                        this.props.projects.map((project) => (
                            <ListItem button onClick={() => {
                                this.props.onSelected(project);
                                this.props.onClose();
                            }}>
                                <ListItemText primary={project.name}/>
                            </ListItem>

                        ))
                    }
                    <ListItem onClick={() => {
                        if(this.state.projectName !== null && this.state.projectName !== "") {
                            this.props.onNewProject(this.state.projectName);
                            this.setState({
                                projectName: null
                            });
                            this.props.onClose()
                        }
                    }}>
                        <TextField variant="standard" label="Project Name" onChange={ (e) => {this.setState({ projectName: e.target.value })}}/>
                        <Button color="secondary" variant="outlined" style={{"marginLeft": "10px"}}>
                            <AddIcon color="secondary" aria-label="Add" />
                            {/*Add*/}
                        </Button>
                    </ListItem>
                </List>




            <DialogActions>
                <Button onClick={this.onClose} color="primary">
                    Close
                </Button>
            </DialogActions>
        </Dialog>
        )
    }

}

export default ProjectsDialog;