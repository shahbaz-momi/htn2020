import React from "react";
import {Dialog, DialogActions, DialogTitle, ListItemText } from "@material-ui/core";
import Button from "@material-ui/core/Button";
import List from "@material-ui/core/List";
import ListItem from "@material-ui/core/ListItem";

class AnnotateView extends React.Component {

    constructor(props) {
        super(props);
    }

    onClose = () => {
        this.props.onClose()
    };

    render() {
        if(this.props.commit === null) {
            return <div></div>
        }

        return (
            <Dialog onClose={this.onClose} open={this.props.open}>
                <DialogTitle>Annotations</DialogTitle>
                <List>
                    {
                        this.props.commit.comments.map((comment) => (
                            <ListItem>
                                <ListItemText primary={comment}/>
                            </ListItem>

                        ))
                    }
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

export default AnnotateView;